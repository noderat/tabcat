# Utilities for couchDB

@tabcat ?= {}
tabcat.couch = {}


# Promise: given an object with the keys "name" and "password", log in the user
tabcat.couch.login = (nameAndPassword) ->
  $.post('/_session', nameAndPassword)


# log out the user. Usually you'll use tabcat.ui.logout()
tabcat.couch.logout = ->
  $.ajax(type: 'DELETE', url: '/_session')


# Promise: get the username of the current user, or null. Will only do this
# once for each page.
#
# For debugging, return user "nobody"
tabcat.couch.getUser = _.once(->
  if window.location.protocol is 'file:'
    $.Deferred().resolve('nobody')
  else
    $.getJSON('/_session').then((sessionDoc) -> sessionDoc.userCtx.name))


# jQuery ought to have this, but it doesn't
putJSON = (url, data, success) ->
  $.ajax(
    contentType: 'application/json'
    data: JSON.stringify(data)
    success: success
    type: 'PUT'
    url: url
  )


# Promise: upload a document to couch DB, and update its _rev field
tabcat.couch.putDoc = (db, doc) ->
  url = "/#{db}/#{doc._id}"
  putJSON(url, doc).then(
    (data, textStatus, xhr) ->
      doc._rev = $.parseJSON(xhr.getResponseHeader('ETag'))
      return doc
  )

# Promise: forcibly upload a document to couch DB, overriding conflicts
#
# You may optionally resolve conflicts with a function merge(oldDoc, newDoc)
# which modifies newDoc accordingly. We always update newDoc's _rev
# to match oldDoc as well.
tabcat.couch.forcePutDoc = (db, doc, merge) ->
  tabcat.couch.putDoc(db, doc).then(
    ((doc) -> doc),
    (xhr) -> switch xhr.status
      when 409
        $.getJSON("/#{db}/#{doc._id}").then(
          ((oldDoc) ->
            # resolve conflict
            if merge?
              merge(oldDoc, doc)
            # update doc's rev
            doc._rev = oldDoc._rev
            # recursively call forcePutDoc, in the unlikely event
            # that the old doc was changed since calling getJSON()
            tabcat.couch.forcePutDoc(db, doc, merge)
          ),
          (xhr) -> switch xhr.status
            # catch docs with bad _rev field (and very rare race conditions)
            when 404
              if doc._rev?
                delete doc._rev
              alert(JSON.stringify(doc))
              tabcat.couch.forcePutDoc(db, doc, merge)
            else
              xhr
        )
      else
        xhr
  )


# create a random UUID. Do this instead of $.couch.newUUID(); it makes sure
# we don't put timestamps in UUIDs, and works offline.
tabcat.couch.randomUUID = () ->
  (Math.floor(Math.random() * 16).toString(16) for _ in [0..31]).join('')
