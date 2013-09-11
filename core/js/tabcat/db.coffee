# a thin layer over CouchDB that handles auto-merging conflicting documents
# and spilling to localStorage on network errors.

@tabcat ?= {}
tabcat.db = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# Promise: download a document from CouchDB
#
# This does NOT look at localStorage; documents are only there temporarily
# until we're able to uplaod them.
#
# This is a very VERY thin wrapper around $.getJSON()
tabcat.db.getDoc = (db, docId) ->
  $.getJSON("/#{db}/#{docId}")


# Promise: upload a document to CouchDB, auto-resolving conflicts,
# and spilling to localStorage on network error.
#
# This will update the _rev field of doc, or, if we spill it to
# localStorage, _rev will be deleted.
#
# If options.expectConflict is true, we always try to GET the old version of
# the doc before we PUT the new one. This is just an optimization.
tabcat.db.putDoc = (db, doc, options) ->
  # optimization: don't even try if there's no network
  if navigator.onLine is false
    tabcat.db.spillDocToLocalStorage(db, doc)
  else
    putDocIntoCouchDB(db, doc, options).then(
      null,
      (xhr) ->
        if xhr.status is 0
          tabcat.db.spillDocToLocalStorage(db, doc)
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

  tabcat.db.getDoc(db, doc._id).then(
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


# Promise: put a document into localStorage for safe-keeping, possibly
# merging with a previously stored version of the document.
#
# (We return a promise for consistency; this returns immediately.)
#
# If doc._rev is set, delete it; we don't track revisions in localStorage.
tabcat.db.spillDocToLocalStorage = (db, doc) ->
  key = "/#{db}/#{doc._id}"

  # most docs don't have a merge function, so save decoding the JSON
  # if there's no merging to do
  if localStorage[key]?
    merge = pickMergeFunc(doc)
    if merge?
      merge(JSON.parse(localStorage[key]), doc)

  if doc._rev?
    delete doc._rev

  localStorage[key] = JSON.stringify(doc)
  return $.Deferred().resolve()
