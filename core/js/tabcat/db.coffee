# a thin layer over CouchDB that handles auto-merging conflicting documents
# and spilling to localStorage on network errors.

@tabcat ?= {}
tabcat.db = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# Promise (can't fail): upload a document to CouchDB, auto-resolving conflicts,
# and spilling to localStorage on any error.
#
# This will update the _rev field of doc, or, if we spill it to
# localStorage, _rev will be deleted.
#
# If options.expectConflict is true, we always try to GET the old version of
# the doc before we PUT the new one. This is just an optimization.
tabcat.db.putDoc = (db, doc, options) ->
  # don't even try if the user isn't authenticated; it'll cause 401s.
  # also don't bother if we're offline (this is an optimization)
  if not tabcat.user.isAuthenticated() or navigator.onLine is false
    tabcat.db.spillDocToLocalStorage(db, doc)
    $.Deferred().resolve()
  else
    putDocIntoCouchDB(db, doc, options).then(
      null,
      ->
        tabcat.db.spillDocToLocalStorage(db, doc)
        $.Deferred().resolve()
    )


# Promise: putDoc() minus handling of offline/network errors. This can fail.
putDocIntoCouchDB = (db, doc, options) ->
  if options?.expectConflict
    resolvePutConflict(db, doc, options)
  else
    tabcat.couch.putDoc(db, doc).then(
      null,
      (xhr) -> switch xhr.status
        when 409
          resolvePutConflict(db, doc, options)
        else
          xhr
    )


# helper for tabcat.db.forcePutDoc()
resolvePutConflict = (db, doc, options) ->
  # make sure to putDoc() first when retrying
  if options?
    options = _.omit(options, 'expectConflict')

  tabcat.couch.getDoc(db, doc._id).then(
    ((oldDoc) ->
      # resolve conflict
      tabcat.db.merge(doc, oldDoc)
      doc._rev = oldDoc._rev

      # recursively call putDoc(), in the unlikely event
      # that the old doc was changed since calling tabcat.couch.getDoc()
      tabcat.db.putDoc(db, doc, options)
    ),
    (xhr) -> switch xhr.status
      # catch new docs with bad _rev field (and very rare race conditions)
      when 404
        if doc._rev?
          delete doc._rev
        tabcat.db.putDoc(db, doc, options)
      else
        xhr
  )



# Merge oldDoc into doc, inferring the method to use from doc.
#
# Currently, we only handle docs with type 'patient'.
tabcat.db.merge = (doc, oldDoc) ->
  merge = pickMergeFunc(doc)

  if merge?
    merge(doc, oldDoc)


# helper for tabcat.couch.merge() and tabcat.db.putDocOffline
pickMergeFunc = (doc) ->
  switch doc.type
    when 'patient'
      tabcat.patient.merge


# Put a document into localStorage for safe-keeping, possibly
# merging with a previously stored version of the document.
#
# If doc._rev is set, delete it; we don't track revisions in localStorage.
tabcat.db.spillDocToLocalStorage = (db, doc) ->
  key = "/#{db}/#{doc._id}"

  # most docs don't have a merge function, so save decoding the JSON
  # if there's no merging to do
  if localStorage[key]?
    merge = pickMergeFunc(doc)
    if merge?
      oldDoc = try JSON.parse(localStorage[key])
      if oldDoc?
        merge(doc, oldDoc)

  if doc._rev?
    delete doc._rev

  localStorage[key] = JSON.stringify(doc)

  # keep track of this as a doc the current user can vouch for
  tabcat.user.addDocSpilled(key)

  localStorage.percentUsedAtLastSpill = tabcat.db.percentOfLocalStorageUsed()

  # activate sync callback if it's not already running
  tabcat.db.startSpilledDocSync()

  return


# are we attempting to sync spilled docs?
spilledDocsSyncIsActive = false

# are we actually succeeding in syncing spilled docs?
syncingSpilledDocs = false

# are we currently syncing spilled docs? (for status bar)
tabcat.db.syncingSpilledDocs = ->
  syncingSpilledDocs


# are there any spilled docs left to sync?
tabcat.db.spilledDocsRemain = ->
  !!getNextDocPathToSync()


# how much is there left to sync?
tabcat.db.percentLeftToSync = ->
  if not tabcat.db.spilledDocsRemain()
    localStorage.removeItem('percentUsedAtLastSpill')

  if not localStorage.percentUsedAtLastSpill?
    return 0

  percentUsedAtLastSpill = parseFloat(localStorage.percentUsedAtLastSpill)
  percentUsed = tabcat.db.percentOfLocalStorageUsed()

  return 100 * Math.min((percentUsed / percentUsedAtLastSpill), 1)



# Kick off syncing of spilled docs. You can pretty much call this anywhere
# (e.g. on page load)
tabcat.db.startSpilledDocSync = ->
  if not spilledDocSyncIsActive
    spilledDocSyncIsActive = true
    syncSpilledDocs()

  return


SYNC_SPILLED_DOCS_WAIT_TIME = 5000


syncSpilledDocs = ->
  # if we're not really logged in, there's nothing to do
  if not tabcat.user.isAuthenticated()
    spilledDocSyncIsActive = false
    return

  # if offline, wait until we're back online
  if navigator.onLine is false
    # not going to use 'online' event; it doesn't seem to be
    # well synced with navigator.onLine
    syncingSpilledDocs = false
    callSyncSpilledDocsAgainIn(SYNC_SPILLED_DOCS_WAIT_TIME)
    return

  # pick a document to upload

  # start with docs spilled by this user
  docPath = tabcat.user.getNextDocSpilled()
  vouchForDoc = !!docPath

  # if there aren't any, grab any doc
  if not docPath?
    docPath = getNextDocPathToSync()

  if not docPath?
    # no more docs; we are done!
    localStorage.removeItem('dbSpillSyncLastDoc')
    spilledDocSyncIsActive = false
    syncingSpilledDocs = false
    return

  localStorage.dbSpillSyncLastDoc = docPath

  doc = try JSON.parse(localStorage[docPath])
  [__, db, docId] = docPath.split('/')

  # whoops, something wrong with this doc, remove it
  if not (doc? and db? and doc._id is docId)
    localStorage.removeItem(docPath)
    tabcat.user.removeDocSpilled(docPath)
    callSyncSpilledDocsAgainIn(0)
    return

  # respect security policy
  user = tabcat.user.get()
  if doc.user? and not (vouchForDoc and doc.user is user)
    if doc.user.slice(-1) isnt '?'
      doc.user += '?'
      doc.uploadedBy = user

  # try syncing the doc
  putDocIntoCouchDB(db, doc).then(
    (->
      # success!
      localStorage.removeItem(docPath)
      tabcat.user.removeDocSpilled(docPath)
      syncingSpilledDocs = true
      callSyncSpilledDocsAgainIn(0)
    ),
    (xhr) ->
      # if it's not a network error, demote to a leftover doc
      if xhr.status isnt 0
        tabcat.user.removeDocSpilled(docPath)

      # if there's an auth issue, user will need to log in again
      # befor we can make any progress
      if xhr.status is 401
        spilledDocSyncIsActive = false
        syncingSpilledDocs = false
        return

      syncingSpilledDocs = false
      callSyncSpilledDocsAgainIn(SYNC_SPILLED_DOCS_WAIT_TIME)
  )

  return


# get the next doc to sync. If you want to prioritize docs spilled by
# this user, use tabcat.user.getNextDocSpilled() first.
getNextDocPathToSync = ->
  docPaths = (path for path in _.keys(localStorage) \
    when path[0] is '/').sort()
  if _.isEmpty(docPaths)
    return null

  docPath = docPaths[0]
  # this allows us to skip over documents and try them later
  if localStorage.dbSpillSyncLastDoc
    index = _.sortedIndex(docPaths, localStorage.dbSpillSyncLastDoc)
    if docPaths[index] = localStorage.dbSpillSyncLastDoc
      index += 1
    if index < docPaths.length
      docPath = docPaths[index]

  return docPath


# hopefully this can keep us from exceeding max recursion depth
callSyncSpilledDocsAgainIn = (milliseconds) ->
  tabcat.ui.wait(milliseconds).then(syncSpilledDocs)
  return


# Estimate % of local storage used. Probably right for the browsers
# we care about!
tabcat.db.percentOfLocalStorageUsed = ->
  return 100 * charsInLocalStorage() / maxCharsInLocalStorage()


# number of chars currently stored in localStorage
charsInLocalStorage = ->
  numChars = 0
  for own key, value of localStorage
    numChars += key.length + value.length

  return numChars


# Loosely based on:
# http://dev-test.nemikor.com/web-storage/support-test/.
# Could be improved
maxCharsInLocalStorage = ->
  ua = navigator.userAgent
  if ua.indexOf('Firefox') isnt -1
    return 4.98 * 1024 * 1024
  else if ua.indexOf('IE') isnt -1
    return 4.75 * 1024 * 1024
  else
    return 2.49 * 1024 * 1024
