# Utilities for the TabCAT UI (both the console and tasks)

# Functions which merely read from the UI to support tasks (especially event
# logging) go in tabcat.task, not tabcat.ui

@tabcat ?= {}
tabcat.ui = {}


# Several things need to be done to make a web page look like an app.
#
# To turn off bounce/scrolling, call tabcat.ui.turnOffBounce() and
# add the "fullscreen" CSS class to html and body (in ../css/tabcat.css)
#
# To turn off zooming, add this tag to head:
#
# <meta name="viewport" content="initial-scale=1.0, minimum-scale=1.0,
# maximum-scale=1.0, user-scalable=no">
#
# To turn off text selection, add the "unselectable" CSS class to body

# close encounter, and redirect to the encounter page
tabcat.ui.closeEncounter = () ->
  options = {}
  patientCode = tabcat.encounter.getPatientCode()
  if patientCode?
    options.closedEncounterWith = patientCode

  tabcat.encounter.close().always(->
    window.location = (
      '../core/create-encounter.html' + tabcat.ui.encodeHashJSON(options))
  )


# Register a click immediately on tap/mouseup, rather than waiting for
# a double-click (requires fastclick.js)
tabcat.ui.enableFastClick = ->
  $(-> FastClick.attach(document.body))


tabcat.ui.fixAspectRatio = ($element, ratio) ->
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
      tabcat.ui.fixAspectRatio(e, ratio)

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
tabcat.ui.linkEmToPercentOfHeight = ($element) ->
  if not $element?
    $element = $('body')
  else
    $element = $($element)

  # handle multiple elements correctly
  if $element.length > 1
    for e in $element
      tabcat.ui.linkEmToPercentOfHeight(e)

  fixElement = ->
    # for font-size, "%" means % of default font size, not % of height.
    sizeInPx = $element.height() / 100
    $element.css('font-size': sizeInPx + 'px')

  fixElement($element)

  $(window).resize(fixElement)


# update the encounter clock on the statusBar
tabcat.ui.updateEncounterClock = ->
  # handle end of encounter gracefully
  if tabcat.encounter.isOpen()
    now = tabcat.clock.now()

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
tabcat.ui.updateOfflineStatus = ->
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
offlineStatusTypeAndHtml = ->
  now = $.now()

  appcache = window.applicationCache

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
  if not tabcat.db.spilledDocsRemain()
    return ''

  percentFull = tabcat.db.percentOfLocalStorageUsed()
  percentFullHtml = Math.min(percentFull, 100).toFixed(1) + '% full'
  if percentFull >= LOCAL_STORAGE_WARNING_THRESHOLD
    percentFullHtml = '<span class="warning">' + percentFullHtml + '</span>'

  return percentFullHtml





# update the statusBar div, populating it if necessary
tabcat.ui.updateStatusBar = ->
  $statusBar = $('#statusBar')

  # populate with new HTML if we didn't already
  if $statusBar.find('div.left').length is 0
    $statusBar.html(
      """
      <div class="left">
        <img class="banner" src="img/banner-white.png">
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

    $statusBar.find('button.login').on('click', (event) ->
      button = $(event.target)
      if button.text() == 'Log Out'
        tabcat.ui.logout()
      else
        tabcat.ui.requestLogin()
    )

  emailP = $statusBar.find('p.email')
  button =  $statusBar.find('button.login')
  encounterP = $statusBar.find('p.encounter')

  user = tabcat.user.get()

  if user?
    emailP.text(user)
    button.text('Log Out')
  else
    emailP.text('not logged in')
    button.text('Log In')

  button.show()

  # only check offline status occasionally
  tabcat.ui.updateOfflineStatus()
  tabcat.ui.updateStatusBar.offlineInterval = window.setInterval(
    tabcat.ui.updateOfflineStatus, 500)

  # don't show encounter info unless patient is logged in
  patientCode = tabcat.encounter.getPatientCode()
  if patientCode? and user?
    encounterNum = tabcat.encounter.getNum()
    encounterNumText = if encounterNum? then ' #' + encounterNum else ''

    encounterP.text(
      'Encounter' + encounterNumText + ' with Patient ' + patientCode)

    if not tabcat.ui.updateStatusBar.clockInterval?
      tabcat.ui.updateStatusBar.clockInterval = window.setInterval(
        tabcat.ui.updateEncounterClock, 50)
  else
    encounterP.empty()
    if tabcat.ui.updateStatusBar.clockInterval?
      window.clearInterval(tabcat.ui.updateStatusBar.clockInterval)
    $statusBar.find('p.clock').empty()



# Promise: log in.
#
# On success, note that the patient does not have the device, and
# redirect to the appropriate page.
#
# Set user to null to re-enter current user's password
tabcat.ui.login = (user, password) ->
  previousUser = tabcat.user.get()
  tabcat.user.login(user, password).then(->
    tabcat.task.patientHasDevice(false)

    destPath = 'create-encounter.html'
    # respect srcPath unless we switched user accounts
    srcPath = tabcat.ui.srcPath()
    if srcPath? and not (previousUser? and previousUser isnt user)
      destPath = srcPath

    window.location = destPath
  )


# Promise: log out, warning that this will close the current encounter.
#
# On success, redirect to the login page
tabcat.ui.logout = ->
  if tabcat.encounter.isOpen()
    if not window.confirm(
      'Logging out will close the current encounter. Proceed?')
      return

  tabcat.user.logout().always(->
    window.location = (
      '../core/login.html' + tabcat.ui.encodeHashJSON(loggedOut: true))
  )


# redirect to the login page
tabcat.ui.requestLogin = ->
  tabcat.ui.detour('../core/login.html')


# redirect to the enter-password page
tabcat.ui.requestPassword = ->
  tabcat.ui.detour('../core/enter-password.html')



# Promise: force the user to log in to view this page.
#
# If we're online, actually check the user's session against the DB.
tabcat.ui.requireUser = ->
  if not tabcat.user.get()
    tabcat.ui.requestLogin()
    return $.Deferred().resolve()  # for consistency

  tabcat.couch.getUser().then(
    ((user) ->
      if not (user? and tabcat.user.isAuthenticated())
        tabcat.ui.requestPassword()
    ),
    (xhr) ->
      if xhr.status is 0
        $.Deferred().resolve()
      else
        xhr
  )


# force the user to log in to view this page, and to create an encounter
tabcat.ui.requireUserAndEncounter = ->
  tabcat.ui.requireUser()

  if not tabcat.encounter.isOpen()
    tabcat.ui.detour('../core/create-encounter.html')


# redirect to the given page, with the intent of being redirected back
tabcat.ui.detour = (path) ->
  srcPath = window.location.pathname + window.location.hash
  window.location = path + tabcat.ui.encodeHashJSON(srcPath: srcPath)


# return srcPath from the hash, if it's set and is actually a path
#
# common usage: window.location = tabcat.ui.srcPath() ? 'default.html'
tabcat.ui.srcPath = ->
  srcPath = tabcat.ui.readHashJSON().srcPath
  # only allow redirects to a different path, not to other sites
  if srcPath? and srcPath.substring(0, 1) is '/'
    return srcPath
  else
    return null


# read a json from the HTML fragment
tabcat.ui.readHashJSON = ->
  (try JSON.parse(decodeURIComponent(window.location.hash.substring(1)))) ? {}


# encode json into HTML fragment. This includes the leading "#"
tabcat.ui.encodeHashJSON = (json) ->
  return '#' + encodeURIComponent(JSON.stringify(json))


# Don't allow the document to scroll past its boundaries. This only works
# if your document isn't larger than the viewport.
tabcat.ui.turnOffBounce = ->
  $(document).bind('touchmove', (event) ->
    event.preventDefault())


# Wrap the given element in a way that requires landscape mode
#
# Don't use this on the <body> element!
tabcat.ui.requireLandscapeMode = ($element) ->
  $element = $($element)

  $pleaseReturnDiv = $(
    '<div class="fullscreen portrait-show blueBackground"></div>')
  $pleaseReturnDiv.html('<p>Please return to landscape mode</p>')

  $element.wrap('<div class="fullscreen requireLandscapeMode"></div>')
  $element.addClass('portrait-hide')
  $element.parent().append($pleaseReturnDiv)
  tabcat.ui.linkEmToPercentOfHeight($pleaseReturnDiv)


# Make a Deferred that resolves after the given number of milliseconds
tabcat.ui.wait = (milliseconds) ->
  deferred = $.Deferred()
  window.setTimeout((-> deferred.resolve()), milliseconds)
  return deferred
