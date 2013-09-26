# Utilities for couchDB

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
      # TODO: move this silliness to tabcat.user
      (xhr) ->
        if xhr.status is 0 and navigator.onLine is false
          $.Deferred().resolve('???')
        else
          xhr
    )
)


# keys that always have to be JSON
COUCHDB_JSON_KEYS = ['key', 'keys', 'startkey', 'endkey']

# Promise: download a document from CouchDB
#
# You can optionally specify query params (for querying views, etc.)
#
# This is a very VERY thin wrapper around $.getJSON()
tabcat.couch.getDoc = (db, docId, queryParams) ->
  query = ''
  if queryParams?
    for own key, value of queryParams
      if key in COUCHDB_JSON_KEYS
        value = JSON.stringify(value)
      if query
        query += '&'
      else
        query += '?'
      query += "#{key}=#{encodeURIComponent(value)}"

  $.getJSON("/#{db}/#{docId}#{query}")


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
# You RARELY want to use this; tabcat.db.putDoc handles this better.
tabcat.couch.putDoc = (db, doc) ->
  url = "/#{db}/#{doc._id}"
  putJSON(url, doc).then(
    (data, textStatus, xhr) ->
      doc._rev = $.parseJSON(xhr.getResponseHeader('ETag'))
      return
  )
