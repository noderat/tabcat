# Utilities for couchDB
#
# This also automatically handles:
# - intelligently resolving conflicts based on doc type
# - spilling docs to localStorage when we're offline

@tabcat ?= {}
tabcat.couch = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# create a random UUID. Do this instead of $.couch.newUUID(); it makes sure
# we don't put timestamps in UUIDs, and works offline.
tabcat.couch.randomUUID = () ->
  (Math.floor(Math.random() * 16).toString(16) for _ in [0..31]).join('')


# Promise: given an object with the keys "name" and "password", log in the user
tabcat.couch.login = (nameAndPassword) ->
  $.post('/_session', nameAndPassword)


# log out the user. Usually you'll use tabcat.ui.logout()
tabcat.couch.logout = ->
  $.ajax(type: 'DELETE', url: '/_session')


# Promise: get the username of the current user, or null. Will only do this
# once for each page.
tabcat.couch.getUser = _.once(->
  if window.location.protocol is 'file:'
    # for ease of debugging
    $.Deferred().resolve('nobody')
  else
    $.getJSON('/_session').then(
      ((sessionDoc) -> sessionDoc.userCtx.name),
      (xhr) ->
        if xhr.status is 0 and navigator.onLine is false
          '???'
        else
          xhr
    )
)


# jQuery ought to have this, but it doesn't
putJSON = (url, data, success) ->
  $.ajax(
    contentType: 'application/json'
    data: JSON.stringify(data)
    success: success
    type: 'PUT'
    url: url
  )


# Promise: upload a document to couch DB, and update its _rev field.
#
# If we're currently offline, put the document into localStorage instead
# and delete its _rev field.
tabcat.couch.putDoc = (db, doc) ->
  tabcat.couch.putDocOnline(db, doc).then(
    null,
    (xhr) ->
      if xhr.status is 0 and navigator.onLine is false
        tabcat.couch.putDocOffline(db, doc)
        return $.Deferred().resolve()
      else
        xhr
  )


# Promise: upload a document to couch DB, and update its _rev field.
# (usually you'll want to use putDoc())
tabcat.couch.putDocOnline = (db, doc) ->
  url = "/#{db}/#{doc._id}"
  putJSON(url, doc).then(
    (data, textStatus, xhr) ->
      doc._rev = $.parseJSON(xhr.getResponseHeader('ETag'))
      return
  )


# Promise: forcibly upload a document to couch DB, overriding/merging with
# the old doc on conflict (see tabcat.couch.merge()), and update doc._rev
# accordingly.
#
# If we're offline, spill to localStorage and delete doc._rev.
#
# If options.expectConflict is true, we always try to GET the old version of
# the doc before we PUT the new one. This is just an optimization.
tabcat.couch.forcePutDoc = (db, doc, options) ->
  tabcat.couch.forcePutDocOnline(db, doc, options).then(
    null,
    (xhr) ->
      if xhr.status is 0 and navigator.onLine is false
        tabcat.couch.putDocOffline(db, doc)
        return $.Deferred().resolve()
      else
        xhr
  )


# same as forcePutDoc(), but without spilling to localStorage when offline
tabcat.couch.forcePutDocOnline = (db, doc, options) ->
  if options?.expectConflict
    resolvePutConflict(db, doc, options)
  else
    tabcat.couch.putDoc(db, doc).then(
      ((doc) -> doc),
      (xhr) -> switch xhr.status
        when 409
          resolvePutConflict(db, doc, options)
        else
          xhr
    )


# helper for tabcat.couch.forcePutDoc()
resolvePutConflict = (db, doc, options) ->
  # make sure to putDoc() first when retrying
  options = _.omit(options, 'expectConflict')

  $.getJSON("/#{db}/#{doc._id}").then(
    ((oldDoc) ->
      # resolve conflict
      merge = tabcat.couch.inferMergeFunc(doc)
      if merge?
        merge(oldDoc, doc)

      doc._rev = oldDoc._rev

      # recursively call forcePutDoc, in the unlikely event
      # that the old doc was changed since calling getJSON()
      tabcat.couch.forcePutDoc(db, doc, options)
    ),
    (xhr) -> switch xhr.status
      # catch docs with bad _rev field (and very rare race conditions)
      when 404
        if doc._rev?
          delete doc._rev
        tabcat.couch.forcePutDoc(db, doc, options)
      else
        xhr
  )


# Merge oldDoc into doc, inferring the method to use from doc.
#
# Currently, we only handle docs with type 'patient'.
tabcat.couch.merge = (doc, oldDoc) ->
  merge = pickMergeFunc(doc)

  if merge?
    merge(doc, oldDoc)


# helper for tabcat.couch.merge() and tabcat.couch.putDocOffline
pickMergeFunc = (doc) ->
  switch doc.type
    when 'patient'
      tabcat.patient.merge


# Put a document into localStorage for safe-keeping, possibly merging with a
# previously stored version of the document.
#
# If doc._rev is set, delete it; we don't track revisions in localStorage.
#
# (This doesn't return a promise, it just returns.)
tabcat.couch.putDocOffline = (db, doc) ->
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
  return
