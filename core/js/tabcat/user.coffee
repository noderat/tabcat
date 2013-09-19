# Utilities for managing the current user's
#
# login/logout should go here, but hasn't been moved yet

@tabcat ?= {}
tabcat.user = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# login logic is currently in the JS for the login page (js/login.coffee)


# Promise: log out user, clean up the current encounter
#
# Usually you'll want to use tabcat.ui.logout()
tabcat.user.logout = ->
  tabcat.user.clearDocsSpilled()

  tabcat.encounter.close().then(->
    tabcat.couch.logout().then(->
      # delete the login cookie manually until I can get logout to work
      # in Safari standalone mode
      document.cookie = 'AuthSession=; expires=Thu, 01-Jan-70 00:00:01 GMT;'
      return
    )
  )


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
  if not localStorage.userDocsSpilled
    return

  if path is tabcat.user.getNextDocSpilled()
    localStorage.userDocsSpilled = (
      localStorage.userDocsSpilled[(path.length + 1)..])
  else
    localStorage.userDocsSpilled = (
      _without(tabcat.user.getDocsSpilled(), path)).join(' ')
  return
