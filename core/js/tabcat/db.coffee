# a thin layer over CouchDB that handles auto-merging conflicting documents
# and spilling to localStorage on network errors.

@tabcat ?= {}
tabcat.db = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# Promise: upload a document to CouchDB, auto-resolving conflicts,
# and spilling to localStorage on network error.
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
      (xhr) ->
        # spill to local storage even if there's an error
        tabcat.db.spillDocToLocalStorage(db, doc)
        if xhr.status is 0
          $.Deferred().resolve()
        else
          xhr
    )


# putDoc() minus handling of offline/network errors
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
      # that the old doc was changed since calling getJSON()
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

  # activate sync callback if it's not already running
  tabcat.db.startSpilledDocSync()

  return


# Kick off syncing of spilled docs. You can pretty much call this anywhere
# (e.g. on page load)
tabcat.db.startSpilledDocSync = ->
  if not syncSpilledDocsIsActive
    syncSpilledDocsIsActive = true
    syncSpilledDocs()

  return


syncSpilledDocsIsActive = false

SYNC_SPILLED_DOCS_WAIT_TIME = 5000


syncSpilledDocs = ->
  # if we're not really logged in, there's nothing to do
  if not tabcat.user.isAuthenticated()
    syncSpilledDocsIsActive = false
    return

  # if offline, wait until we're back online
  if navigator.onLine is false
    # not going to use 'online' event; it doesn't seem to be
    # well synced with navigator.onLine
    callSyncSpilledDocsAgainIn(SYNC_SPILLED_DOCS_WAIT_TIME)
    return

  # pick a document to upload. start with list of docs spilled by
  # this user, and then handle other docs
  docPath = getNextDocPathToSync()
  if not docPath?
    # no more docs; we are done!
    localStorage.removeItem('dbSpillSyncLastDoc')
    syncSpilledDocsIsActive = false
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

  # try syncing the doc
  putDocIntoCouchDB(db, doc).then(
    (->
      # success!
      localStorage.removeItem(docPath)
      tabcat.user.removeDocSpilled(docPath)
      callSyncSpilledDocsAgainIn(0)
    ),
    (xhr) ->
      # if there's an auth issue, wait for user to be prompted
      # to log in again
      if xhr.status is 401
        syncSpilledDocsIsActive = false
        return

      if xhr.status isnt 0
        # demote to a leftover doc
        tabcat.user.removeDocSpilled(docPath)
      callSyncSpilledDocsAgainIn(SYNC_SPILLED_DOCS_WAIT_TIME)
  )

  return


# get the next doc to sync, giving priority to docs spilled by this user
getNextDocPathToSync = ->
  docPath = tabcat.user.getNextDocSpilled()
  if not docPath?
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
