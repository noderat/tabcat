# Managing the current user's session.
#
# Whenever the user logs in or logs out, we record their name in
# localStorage.user. This is good enough for most things.
#
# If we're offline, users can still log in, but we don't check their
# password. You can tell this has happened because
# tabcat.user.isAuthenticated() returns false.
#
# Generally, if we come back online, we ask the user to log in for real
# once the patient no longer has the device, so we can start uploading
# spilled data.

@tabcat ?= {}
tabcat.user = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# Get the current user, or null. This may be a lie because we just
# look at localStorage; to ask the DB, use tabcat.couch.getUser()
tabcat.user.get = ->
  localStorage.user ? null


# Return true if the user "logged in" while we were offline. If this
# is true, there's no point in trying to store stuff in the DB.
tabcat.user.isAuthenticated = ->
  !!localStorage.userIsAuthenticated


# Promise: log the given user in with the given password.
#
# Usually you'll want to use tabcat.ui.login()
#
# This also sets localStorage.user on success. If there's a network error,
# just treat user as logged in until we're back online (the only real
# security is on the DB server).
tabcat.user.login = (user, password) ->
  tabcat.couch.login(user, password).then(
    (->
      localStorage.userIsAuthenticated = 'true'
      $.Deferred().resolve()
    ),
    (xhr) ->
      if xhr.status is 0
        localStorage.removeItem('userIsAuthenticated')
        $.Deferred().resolve()
      else
        xhr
  ).then(->
    # if we're not just re-authenticating the same user, clean out
    # old encounter info, and don't vouch for other people's docs.
    if localStorage.user isnt user
      tabcat.encounter.clear()
      tabcat.user.clearDocsSpilled()

      localStorage.user = user
  )


# Promise: log out user, clean up the current encounter
#
# Usually you'll want to use tabcat.ui.logout()
tabcat.user.logout = ->
  localStorage.removeItem('user')
  localStorage.removeItem('userIsAuthenticated')
  tabcat.user.clearDocsSpilled()

  # the first then is just like .always(), except we return the promise
  # from logout(), not the one from encounter.close()
  tabcat.encounter.close().then(null, $.Deferred().resolve()).then(
    tabcat.couch.logout())


# localStorage.userDocsSpilled keeps a space-separated list of spilled
# docs that the current user can vouch for
tabcat.user.clearDocsSpilled = ->
  localStorage.removeItem('userDocsSpilled')


# get the first doc in the list of spilled docs, or null if there are none
tabcat.user.getNextDocSpilled = ->
  spilled = localStorage.userDocsSpilled
  if not spilled
    return null

  end = spilled.indexOf(' ')
  if end is -1 then end = spilled.length
  return spilled[0...end]


# get all docs spilled by the current user
tabcat.user.getDocsSpilled = ->
  if localStorage.userDocsSpilled
    localStorage.userDocsSpilled.split(' ')
  else
    []


# add the given path to userDocsSpilled,
tabcat.user.addDocSpilled = (path) ->
  spilled = localStorage.userDocsSpilled or ''

  # don't bother with paths that are already there
  if (path is tabcat.user.getNextDocSpilled() or \
      spilled.indexOf(' ' + path) != -1)
    return

  if spilled
    localStorage.userDocsSpilled = spilled + (' ' + path)
  else
    localStorage.userDocsSpilled = path
  return


# remove the given path from userDocsSpilled, optimizing for it
# removing the first path or userDocsSpilled being empty
tabcat.user.removeDocSpilled = (path) ->
  if localStorage.userDocsSpilled
    if path is tabcat.user.getNextDocSpilled()
      localStorage.userDocsSpilled = (
        localStorage.userDocsSpilled[(path.length + 1)..])
    else
      localStorage.userDocsSpilled = (
        _.without(tabcat.user.getDocsSpilled(), path)).join(' ')

  if localStorage.userDocsSpilled is ''
    localStorage.removeItem('userDocsSpilled')

  return
