###
Copyright (c) 2013, Regents of the University of California
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
# Utilities for couchDB

@TabCAT ?= {}
TabCAT.Couch = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# convert options.now (timestamp, from $.now()) and options.timeout to a
# timeout for use with couchDB methods. This allows a multi-step
# process to timeout after a fixed time (rather than having a certain
# timeout per step).
#
# if it's supposed to time out sometime in the past, return 1 (one ms)
timeoutFrom = (options) ->
  if options?.now? and options.timeout?
    Math.max(options.now + options.timeout - $.now(), 1)
  else
    options?.timeout


# create a random UUID. Do this instead of $.couch.newUUID(); it makes sure
# we don't put timestamps in UUIDs, and works offline.
TabCAT.Couch.randomUUID = () ->
  (Math.floor(Math.random() * 16).toString(16) for _ in [0..31]).join('')


# Promise: log the user in. Usually you'll use TabCAT.UI.login()
TabCAT.Couch.login = (user, password) ->
  $.post('/_session', name: user, password: password)


# log out the user. Usually you'll use TabCAT.UI.logout()
TabCAT.Couch.logout = ->
  $.ajax(type: 'DELETE', url: '/_session')


# Promise: get the username of the current user, or null
#
# options:
# - now: timeout is relative to this time (set this to $.now())
# - timeout: timeout in milliseconds
TabCAT.Couch.getUser = (options) ->
  TabCAT.Couch.getDoc(
    null, '/_session', _.pick(options ? {}, 'now', 'timeout')).then(

    (sessionDoc) -> sessionDoc.userCtx.name
  )


# keys that always have to be JSON
COUCHDB_JSON_KEYS = ['key', 'keys', 'startkey', 'endkey']


# make the given DB name and doc ID into a URL, or, if DB is not
# set, just return docId (for relative URLs)
dbUrl = (db, docId) ->
  if db?
    "/#{db}/#{docId}"
  else
    docId


# Promise: download a (JSON) document from CouchDB
#
# If db is null, just use docId as the URL.
#
# You can optionally specify query params (for querying views, etc.)
#
# options:
# - now: timeout is relative to this time (set this to $.now())
# - query: query parameters
# - timeout: timeout in milliseconds
TabCAT.Couch.getDoc = (db, docId, options) ->
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
    timeout: timeoutFrom(options)
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
# You RARELY want to use this; TabCAT.DB.putDoc() handles this more robustly.
#
# If db is null, just use docId as the URL.
#
# You can set timeout in milliseconds with options.timeout
TabCAT.Couch.putDoc = (db, doc, options) ->
  ajaxParams =
    contentType: 'application/json'
    data: JSON.stringify(doc)
    timeout: timeoutFrom(options)
    type: 'PUT'
    url: dbUrl(db, doc._id)

  $.ajax(ajaxParams).then(
    (data, textStatus, xhr) ->
      doc._rev = JSON.parse(xhr.getResponseHeader('ETag'))
      return
  )


# Promise: return a list of all design docs for a DB, sorted by ID.
# - now: timeout is relative to this time (set this to $.now())
# - timeout: timeout in milliseconds
TabCAT.Couch.getAllDesignDocs = (db, options) ->
  if not db?
    throw Error("must specify a db")

  # force timeout to be relative to now
  if options?.timeout? and not options.now?
    options = _.extend(options, now: $.now())

  # don't pass parameters to _all_docs (e.g. startkey="_design/")
  # because we want to be able to use the _all_docs stored in the
  # application cache.
  TabCAT.Couch.getDoc(db, '_all_docs', timeout: timeoutFrom(options)).then(
    (response) ->
      designDocIds = (row.key for row in response.rows \
                      when row.key[0..7] is '_design/')

      designDocPromises = (
        TabCAT.Couch.getDoc(db, docId, timeout: timeoutFrom(options)) \
        for docId in designDocIds)

      $.when(designDocPromises...).then(
        (designDocs...) -> designDocs
      )
  )
