# Utilities for couchDB
#
# You usually won't need to use these directly; use tabcat.db instead

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
# (Usually you'll want to use tabcat.db.putDoc())
tabcat.couch.putDoc = (db, doc) ->
  url = "/#{db}/#{doc._id}"
  putJSON(url, doc).then(
    (data, textStatus, xhr) ->
      doc._rev = $.parseJSON(xhr.getResponseHeader('ETag'))
      return
  )
