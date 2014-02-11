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
# Utilities for the TabCAT UI (both the console and tasks)

# Functions which merely read from the UI to support tasks (especially event
# logging) go in TabCAT.Task, not TabCAT.UI

@TabCAT ?= {}
TabCAT.UI = {}


# doesn't make sense to prompt the user for a password more than 2 seconds
# or so after the page loads
DEFAULT_REQUIRE_USER_TIMEOUT = 2000

# Several things need to be done to make a web page look like an app.
#
# To turn off bounce/scrolling, call TabCAT.UI.turnOffBounce() and
# add the "fullscreen" CSS class to html and body (in ../css/tabcat.css)
#
# To turn off zooming, add this tag to head:
#
# <meta name="viewport" content="initial-scale=1.0, minimum-scale=1.0,
# maximum-scale=1.0, user-scalable=no">
#
# To turn off text selection, add the "unselectable" CSS class to body

# Register a click immediately on tap/mouseup, rather than waiting for
# a double-click (requires fastclick.js)
TabCAT.UI.enableFastClick = ->
  $(-> FastClick.attach(document.body))


TabCAT.UI.fixAspectRatio = ($element, ratio) ->
  # Ensure that $element has the given aspect ratio (width / height),
  # and make it as large as possible within the bounds of its parent
  # element. This property will be preserved on window resize.
  #
  # We do this by setting its left, right, width, etc.
  # to the appropriate percentage. We do not set border, margin, or padding.
  #
  # This helps ensure that tasks look the same on different devices.

  # TODO: handle nested elements properly (currently we'll get wrong results
  # if you call this on an element and then on its parent)

  # TODO: set max height in inches so that tests will display at the same size
  # on different devices, assuming screen is large enough. Use
  # https://github.com/tombigel/detect-zoom or something similar to determine
  # real pixel size (devices generally use a fake dpi by convention).
  $element = $($element)

  # handle multiple elements correctly
  if $element.length > 1
    for e in $element
      TabCAT.UI.fixAspectRatio(e, ratio)

  fixElement = ->
    $parent = $($element.parent())
    parentWidth = $parent.width()
    parentHeight = $parent.height()
    parentRatio = parentWidth / parentHeight

    if parentRatio > ratio
      # parent is too wide, need gap on left and right
      gap = 100 * (parentRatio - ratio) / parentRatio / 2

      $element.css(
        position: 'absolute'
        left: gap + '%'
        right: 100 - gap + '%'
        width: 100 - 2 * gap + '%'
        top: '0%'
        bottom: '100%'
        height: '100%'
      )
    else
      # parent is too narrow, need gap on top and bottom
      gap = (100 * (1 / parentRatio - 1 / ratio) * parentRatio / 2)

      $element.css(
        position: 'absolute'
        left: '0%'
        right: '100%'
        width: '100%'
        top: gap + '%'
        bottom: 100 - gap + '%'
        height: 100 - 2 * gap + '%'
      )

  fixElement($element)

  $(window).resize(fixElement)


# Make 1em equivalent to 1% of the given element's height This will be
# preserved on window resize. This ensures we get similar text layouts on
# different devices.
#
# Make sure to wrap the text inside some other element (e.g. span) and set
# font-size on that (since this works by setting font-size)
#
# Make sure your element is part of the DOM (that is, has a meaningful height)
# before calling this function on it.
#
# (TODO: check the above with element.closest('html'))
#
# Also, it is a good not to show text in elements sized this way until after
# this method is called.
TabCAT.UI.linkEmToPercentOfHeight = ($element) ->
  if not $element?
    $element = $('body')
  else
    $element = $($element)

  # handle multiple elements correctly
  if $element.length > 1
    for e in $element
      TabCAT.UI.linkEmToPercentOfHeight(e)

  fixElement = ->
    # for font-size, "%" means % of default font size, not % of height.
    sizeInPx = $element.height() / 100
    $element.css('font-size': sizeInPx + 'px')

  fixElement($element)

  $(window).resize(fixElement)


# update the encounter clock on the statusBar
TabCAT.UI.updateEncounterClock = ->
  # handle end of encounter gracefully
  if TabCAT.Encounter.isOpen()
    now = TabCAT.Clock.now()

    seconds = Math.floor(now / 1000) % 60
    if seconds < 10
      seconds = '0' + seconds
    minutes = Math.floor(now / 60000) % 60
    if minutes < 10
      minutes = '0' + minutes
    hours = Math.floor(now / 3600000)
    time = hours + ':' + minutes + ':' + seconds

    $('#statusBar p.clock').text(time)
  else
    $('#statusBar p.clock').empty()


# warn when local storage is more than 75% full
# typical tasks use 0.5% of browser storage
LOCAL_STORAGE_WARNING_THRESHOLD = 75


# keep status messages for at least a second
OFFLINE_STATUS_MIN_CHANGE_TIME = 2000

keepOfflineStatusUntil = null
lastOfflineStatusType = 0

# update the offline status on the statusBar, while attempting not
# to flicker status messages so quickly that we can't read them
TabCAT.UI.updateOfflineStatus = ->
  now = $.now()
  [statusType, statusHtml] = offlineStatusTypeAndHtml()

  if (keepOfflineStatusUntil? and now < keepOfflineStatusUntil \
      and statusType isnt lastOfflineStatusType)
    return

  # don't bother holding blank message for a second
  if statusHtml
    lastOfflineStatusType = statusType
    keepOfflineStatusUntil = now + OFFLINE_STATUS_MIN_CHANGE_TIME

  $('#statusBar').find('p.offline').html(statusHtml)


# return the type of offline status and html to display.
#
# This also swaps in an updated application cache, if necessary
offlineStatusTypeAndHtml = ->
  now = $.now()

  appcache = window.applicationCache

  # if there's an updated version of the cache ready, swap it in
  if appcache.status is appcache.UPDATEREADY
    appcache.swapCache()

  if navigator.onLine is false
    if (appcache.status is appcache.UNCACHED or \
        appcache.status >= appcache.OBSOLETE)
      return [1, '<span class="warning">PLEASE CONNECT TO NETWORK</span>']
    else
      percentFullHtml = offlineStatusStoragePercentFullHtml()
      if percentFullHtml
        return [2, 'OFFLINE MODE (storage ' + percentFullHtml + ')']
      else
        return [2, 'OFFLINE MODE']

  if appcache.status is appcache.DOWNLOADING
    return [3, 'loading content for offline mode']

  if (appcache.status is appcache.UNCACHED or \
      appcache.status >= appcache.OBSOLETE)
    return [4, '<span class="warning">offline mode unavailable</span>']

  # not exactly offline, but can't sync (maybe wrong network?)
  percentFullHtml = offlineStatusStoragePercentFullHtml()
  if percentFullHtml
    return [5, 'offline storage ' + percentFullHtml]

  return [0, '']


# helper for offlineStatusHtml(). returns "#.#% full" plus markup
offlineStatusStoragePercentFullHtml = ->
  if not TabCAT.DB.spilledDocsRemain()
    return ''

  percentFull = TabCAT.DB.percentOfLocalStorageUsed()
  percentFullHtml = Math.min(percentFull, 100).toFixed(1) + '% full'
  if percentFull >= LOCAL_STORAGE_WARNING_THRESHOLD
    percentFullHtml = '<span class="warning">' + percentFullHtml + '</span>'

  return percentFullHtml


# update the statusBar div, populating it if necessary
#
# this also implicitly unsets patientHasDevice
#
# this is also responsible for swapping in updated versions of the
# application cache (Android browser seems to need this)
TabCAT.UI.updateStatusBar = ->
  TabCAT.Task.patientHasDevice(false)

  $statusBar = $('#statusBar')

  # populate with new HTML if we didn't already
  if $statusBar.find('div.left').length is 0
    $statusBar.html(
      """
      <div class="left">
        <img class="banner" src="img/banner-white.png">
        <span class="version"></span>
        <p class="offline"></p>
      </div>
      <div class="right">
        <p class="email">&nbsp;</p>
        <button class="login" style="display:none"></span>
      </div>
      <div class="center">
        <p class="encounter"></p>
        <p class="clock"></p>
      </div>
      """
    )

    $statusBar.find('.version').text(TabCAT.version)

    $statusBar.find('button.login').on('click', (event) ->
      button = $(event.target)
      if button.text() == 'Log Out'
        TabCAT.UI.logout()
      else
        TabCAT.UI.requestLogin()
    )

  emailP = $statusBar.find('p.email')
  button =  $statusBar.find('button.login')
  encounterP = $statusBar.find('p.encounter')

  user = TabCAT.User.get()

  if user?
    emailP.text(user)
    button.text('Log Out')
  else
    emailP.text('not logged in')
    button.text('Log In')

  button.show()

  # only check offline status occasionally
  TabCAT.UI.updateOfflineStatus()
  TabCAT.UI.updateStatusBar.offlineInterval = window.setInterval(
    TabCAT.UI.updateOfflineStatus, 500)

  # don't show encounter info unless patient is logged in
  patientCode = TabCAT.Encounter.getPatientCode()
  if patientCode? and user?
    encounterNum = TabCAT.Encounter.getNum()
    encounterNumText = if encounterNum? then ' #' + encounterNum else ''

    encounterP.text(
      'Encounter' + encounterNumText + ' with Patient ' + patientCode)

    if not TabCAT.UI.updateStatusBar.clockInterval?
      TabCAT.UI.updateStatusBar.clockInterval = window.setInterval(
        TabCAT.UI.updateEncounterClock, 50)
  else
    encounterP.empty()
    if TabCAT.UI.updateStatusBar.clockInterval?
      window.clearInterval(TabCAT.UI.updateStatusBar.clockInterval)
    $statusBar.find('p.clock').empty()



# Promise: log in.
#
# On success, note that the patient does not have the device, and
# redirect to the appropriate page.
#
# If set, user will automatically be converted to all-lowercase,
# to give case-insensitive behavior.
#
# Set user to null to re-enter current user's password
TabCAT.UI.login = (user, password) ->
  previousUser = TabCAT.User.get()
  TabCAT.User.login(user, password).then(->
    TabCAT.Task.patientHasDevice(false)

    destPath = 'create-encounter.html'
    # respect srcPath unless we switched user accounts
    srcPath = TabCAT.UI.srcPath()
    if srcPath? and not (previousUser? and previousUser isnt user)
      destPath = srcPath

    window.location = destPath
  )


# Promise: log out, warning that this will close the current encounter.
#
# On success, redirect to the login page
TabCAT.UI.logout = ->
  if TabCAT.Encounter.isOpen()
    if not window.confirm(
      'Logging out will close the current encounter. Proceed?')
      return

  TabCAT.User.logout().always(->
    window.location = (
      '../core/login.html' + TabCAT.UI.encodeHashJSON(loggedOut: true))
  )


# redirect to the login page
TabCAT.UI.requestLogin = ->
  TabCAT.UI.detour('../core/login.html')


# redirect to the enter-password page
TabCAT.UI.requestPassword = ->
  TabCAT.UI.detour('../core/enter-password.html')


# Promise: force the user to log in to view this page.
#
# First we check localStorage.user.
#
# Then, if we're online, we also check the user's session against the DB.
# If they're not logged in, prompt for a password unless the patient
# has the device.
#
# You can specify a timeout on checking against the DB in milliseconds with
# options.timeout (default is 2000)
TabCAT.UI.requireUser = (options) ->
  resolved = $.Deferred().resolve()  # for consistency

  # if there's no user whatsoever, we need them to log in before
  # we can start storing data
  if not TabCAT.User.get()
    TabCAT.UI.requestLogin()
    return resolved

  # don't confuse patients by asking for the password
  if TabCAT.Task.patientHasDevice()
    return resolved

  # localStorage says user is logged in. Let's check if the DB agrees
  timeout = options?.timeout ? DEFAULT_REQUIRE_USER_TIMEOUT
  TabCAT.Couch.getUser(timeout: timeout).then(
    ((user) ->
      if not (user is TabCAT.User.get() and TabCAT.User.isAuthenticated())
        TabCAT.UI.requestPassword()
    ),
    (xhr) ->
      # if there's no network, doesn't matter if user is authenticated
      if xhr.status is 0
        $.Deferred().resolve()
      else
        xhr
  )


# force the user to log in to view this page, and to create an encounter
#
# You can specify a timeout in milliseconds with options.timeout
TabCAT.UI.requireUserAndEncounter = (options) ->
  TabCAT.UI.requireUser(options)

  if not TabCAT.Encounter.isOpen()
    TabCAT.UI.detour('../core/create-encounter.html')


# redirect to the given page, with the intent of being redirected back
TabCAT.UI.detour = (path) ->
  srcPath = window.location.pathname + window.location.hash
  window.location = path + TabCAT.UI.encodeHashJSON(srcPath: srcPath)
  return


# return srcPath from the hash, if it's set and is actually a path
#
# common usage: window.location = TabCAT.UI.srcPath() ? 'default.html'
TabCAT.UI.srcPath = ->
  srcPath = TabCAT.UI.readHashJSON().srcPath
  # only allow redirects to a different path, not to other sites
  if srcPath? and srcPath[0] is '/'
    return srcPath
  else
    return null


# read a json from the HTML fragment
TabCAT.UI.readHashJSON = ->
  (try JSON.parse(decodeURIComponent(window.location.hash[1..]))) ? {}


# encode json into HTML fragment. This includes the leading "#"
TabCAT.UI.encodeHashJSON = (json) ->
  return '#' + encodeURIComponent(JSON.stringify(json))


# Don't allow the document to scroll past its boundaries. This only works
# if your document isn't larger than the viewport.
TabCAT.UI.turnOffBounce = ->
  $(document).on('touchmove', (event) -> event.preventDefault())


# Wrap the given element in a way that requires landscape mode
#
# Don't use this on the <body> element!
TabCAT.UI.requireLandscapeMode = ($element) ->
  $element = $($element)

  $pleaseReturnDiv = $(
    '<div class="fullscreen portrait-show blueBackground"></div>')
  $pleaseReturnDiv.html('<p>Please return to landscape mode</p>')

  $element.wrap('<div class="fullscreen requireLandscapeMode"></div>')
  $element.addClass('portrait-hide')
  $element.parent().append($pleaseReturnDiv)
  TabCAT.UI.linkEmToPercentOfHeight($pleaseReturnDiv)


# Make a Deferred that resolves after the given number of milliseconds
TabCAT.UI.wait = (milliseconds) ->
  deferred = $.Deferred()
  window.setTimeout((-> deferred.resolve()), milliseconds)
  return deferred


# used by inSandbox()
SANDBOX_REGEX = \
  /(sandbox|^\d+\.\d+\.\d+\.\d+$)/i


# Infer from the hostname whether we're in sandbox mode. This happens if it
# contains "sandbox" or is an IP address.
#
# Sandbox mode is meant to only affect the UI: different warning messages,
# pre-filled form inputs, etc.
#
# We intentially don't do anything for the hostname "localhost"
# so that it's easy to test non-sandbox mode (use "127.0.0.1" instead).
#
# You can optionally pass in a hostname (by default we use
# window.location.hostname).
TabCAT.UI.inSandbox = (hostname) ->
  SANDBOX_REGEX.test(hostname ? window.location.hostname)
