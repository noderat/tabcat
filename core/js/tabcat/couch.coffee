# Utilities for couchDB

@tabcat ?= {}
tabcat.couch = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# create a random UUID. Do this instead of $.couch.newUUID(); it makes sure
# we don't put timestamps in UUIDs, and works offline.
tabcat.couch.randomUUID = () ->
  (Math.floor(Math.random() * 16).toString(16) for _ in [0..31]).join('')


# Promise: log the user in. Usually you'll use tabcat.ui.login()
tabcat.couch.login = (user, password) ->
  $.post('/_session', name: user, password: password)


# log out the user. Usually you'll use tabcat.ui.logout()
tabcat.couch.logout = ->
  $.ajax(type: 'DELETE', url: '/_session')


# Promise: get the username of the current user, or null
#
# You can specify a timeout in milliseconds with options.timeout
tabcat.couch.getUser = (options) ->
  tabcat.couch.getDoc(null, '/_session', timeout: options?.timeout).then(
    (sessionDoc) -> sessionDoc.userCtx.name)


# keys that always have to be JSON
COUCHDB_JSON_KEYS = ['key', 'keys', 'startkey', 'endkey']


# make the given DB name and doc ID into a URL, or, if DB is not
# set, just return docId (for relative URLs)
dbUrl = (db, docId) ->
  if db?
    "/#{db}/#{docId}"
  else
    docId


# Promise: download a document from CouchDB
#
# If db is null, just use docId as the URL.
#
# You can optionally specify query params (for querying views, etc.)
#
# You can specify query parameters with options.query
# You can specify a timeout in milliseconds with options.timeout
tabcat.couch.getDoc = (db, docId, options) ->
  query = ''
  if options?.query?
    for own key, value of options.query
      if key in COUCHDB_JSON_KEYS
        value = JSON.stringify(value)
      if query
        query += '&'
      else
        query += '?'
      query += "#{key}=#{encodeURIComponent(value)}"

  url = dbUrl(db, docId) + query

  # don't use $.getJSON() because it doesn't allow for timeout
  $.ajax(
    dataType: 'json'
    timeout: options?.timeout
    url: url
  ).then(
    ((doc) -> doc),  # just return a single argument
    # workaround for egregious mobile browser standalone manifest bug
    # see http://goo.gl/WV75t
    (xhr) ->
      if xhr.status is 0 and xhr.statusText is 'error' and xhr.responseText
        try
          return $.Deferred().resolve(JSON.parse(xhr.responseText))
      return xhr
  )


# Promise: upload a document to couch DB, and update its _rev field.
#
# You RARELY want to use this; tabcat.db.putDoc() handles this more robustly.
#
# If db is null, just use docId as the URL.
#
# You can set timeout in milliseconds with options.timeout
tabcat.couch.putDoc = (db, doc, options) ->
  ajaxParams =
    contentType: 'application/json'
    data: JSON.stringify(doc)
    timeout: options?.timeout
    type: 'PUT'
    url: dbUrl(db, doc._id)

  $.ajax(ajaxParams).then(
    (data, textStatus, xhr) ->
      doc._rev = JSON.parse(xhr.getResponseHeader('ETag'))
      return
  )
