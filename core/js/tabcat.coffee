# GLOBALS

tabcat = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# CONSTANTS

DB = 'tabcat-data'
DB_ROOT = '/' + DB + '/'


# UTILITIES

# jQuery ought to have this, but it doesn't
putJSON = (url, data, success) ->
  $.ajax(
    contentType: 'application/json'
    data: JSON.stringify(data)
    success: success
    type: 'PUT'
    url: url
  )

# upload a document to couch DB, and, if successful, update its _rev field
putDoc = (db, doc) ->
  url = "/#{db}/#{doc._id}"
  putJSON(url, doc).then(
    (data, textStatus, xhr) ->
      doc._rev = $.parseJSON(xhr.getResponseHeader('ETag'))
      return doc
  )





# CLOCK

# Timestamps reveal PHI (date of encounter) so instead we store time since
# start of encounter, which is stored in the browser and persists across
# tasks.
#
# Most tasks will only call .now(). Generally, .reset() will be called
# at the start of an encounter (not a task), .clear() will be called at the
# end, and .lastStarted() will be included in standard task data
# (.offset() as well, if we are allowed to store PHI).
#
# If you need to re-open an encounter, call reset() with the last known
# timestamp for that session.

tabcat.clock = {}

# remove encounter clock from local storage
tabcat.clock.clear = ->
  delete localStorage.clockLastStarted
  delete localStorage.clockOffset
  return

# get nominal time since start of encounter when clock was restarted (msec)
tabcat.clock.lastStarted = ->
  tabcat.clock.start()
  return parseInt(localStorage.clockLastStarted)

# milliseconds since start of encounter
tabcat.clock.now = ->
  # evaluate offset before $.now() to avoid negative timestamps when
  # clock is start()ed implicitly
  offset = tabcat.clock.offset()
  return $.now() - offset

# add this to tabcat.clock.now() to get the real timestamp (in msec)
tabcat.clock.offset = ->
  tabcat.clock.start()
  return parseInt(localStorage.clockOffset)

# Reset the clock. Optionally, specify the current time relative to
# start of encounter (in msec)
tabcat.clock.reset = (startAt) ->
  startAt ?= 0
  localStorage.clockLastStarted = startAt
  localStorage.clockOffset = $.now() - startAt
  return  # don't let people depend on return value

# Start the clock, if it's not already started
tabcat.clock.start = (startAt) ->
  if not (localStorage.clockLastStarted and localStorage.clockOffset)
    tabcat.clock.reset()


# CONFIG

# Tabcat-specific configs, such as PHI (Protected Health Information) level

# for more info about PHI see:
# http://www.research.ucsf.edu/chr/HIPAA/chrHIPAAfaq.asp

tabcat.config = {}

# check if we allow Limited Dataset PHI. This allows us to store dates,
# timestamps, city, state, and zipcode
#
# IMPORTANT: Limited PHI should always be stored in a sub-field
# called "limitedPHI" so we can strip it out later if need be.
tabcat.config.canStoreLimitedPHI = (configDoc) ->
  configDoc?.PHI or configDoc?.limitedPHI

tabcat.config.canStorePHI = (configDoc) ->
  configDoc?.PHI

# Promise: get the config document, or return {}
# TODO: fill in missing fields so we don't need the functions above
tabcat.config.get = _.once(->
  $.getJSON(DB_ROOT + 'config').then(
    null,  # pass through success
    (xhr) -> switch xhr.status
      when 404 then $.Deferred().resolve({})
      else xhr  # pass through failure
  )
)



# COUCH

# Utilities for couchDB

tabcat.couch = {}

# Promise:
tabcat.couch.login = (nameAndPassword) ->
  $.post('/_session', nameAndPassword)

tabcat.couch.logout = ->
  $.ajax(type: 'DELETE', url: '/_session')

# Promise: get the username of the current user, or null
tabcat.couch.getUser = ->
  $.getJSON('/_session').then((sessionDoc) -> sessionDoc.userCtx.name)

# Promise: upload a document to couch DB, and update its _rev field
tabcat.couch.putDoc = putDoc

# create a random UUID. Do this instead of $.couch.newUUID(); it makes sure
# we don't put timestamps in UUIDs, and works offline.
tabcat.couch.randomUUID = () ->
  (Math.floor(Math.random() * 16).toString(16) for _ in [0..31]).join('')


# ENCOUNTER

# logic for creating patients and opening encounters with them.

tabcat.encounter = {}

# randomly generate a 6-digit patient code
tabcat.encounter.generatePatientCode = ->
  String(Math.floor(tabcat.math.randomUniform(1000000, 2000000))).substring(1)

# get the patient code
tabcat.encounter.getPatientCode = ->
  localStorage.patientCode

# get the (random) ID of this encounter
tabcat.encounter.getEncounterId = ->
  localStorage.encounterId

# get the encounter number. This should only be used in the UI, not
# stored in the database. May be undefined.
tabcat.encounter.getEncounterNum = ->
  try
    parseInt(localStorage.encounterNum)
  catch error
    undefined

# Promise: start an encounter and update patient doc and localStorage
# appropriately
#
# Sample usage:
#
# tabcat.encounter.create(patientCode: "AAAAA").then(
#   (patientDoc) -> ... # proceed,
#   (xhr) -> ... # show error message on failure)
tabcat.encounter.create = (options) ->
  patientCode = String(options?.patientCode ? 0)
  patientDocId = 'patient-' + patientCode
  encounterId = tabcat.couch.randomUUID()

  date = new Date

  encounterDoc =
    _id: encounterId
    patientCode: patientCode
    year: date.getFullYear()

  tabcat.clock.reset()

  tabcat.config.get().then((configDoc) ->
    # store today's date, and timestamp if we're allowed
    if tabcat.config.canStoreLimitedPHI(configDoc)
      encounterDoc.limitedPHI =
        month: date.getMonth()
        day: date.getDate()
        clockOffset: tabcat.clock.offset()
  )

  updatePatientDoc = (patientDoc) ->
    patientDoc.encounterIds ?= []
    patientDoc.encounterIds.push(encounterId)
    putDoc(DB, patientDoc)

  tabcat.couch.getUser().then((user) ->
    encounterDoc.user = user
    putDoc(DB, encounterDoc).then(->
      $.getJSON(DB_ROOT + patientDocId).then(
        updatePatientDoc,
        (xhr) -> switch xhr.status
          when 404 then updatePatientDoc(_id: patientDocId, type: 'patient')
          else xhr  # pass failure through
      ).then((patientDoc) ->
        localStorage.patientCode = patientCode
        localStorage.encounterId = encounterId
        localStorage.encounterNum = patientDoc.encounterIds.length
        return patientDoc
      )
    )
  )

# finish the current patient encounter. this clears local storage even
# if there is a problem updating the encounter doc
tabcat.encounter.close = ->
  encounterId = tabcat.encounter.getEncounterId()
  tabcat.encounter.clear()

  if encounterId?
    $.getJSON(DB_ROOT + encounterId).then((encounterDoc) ->
      encounterDoc.finishAt = tabcat.clock.now()
      putDoc(DB, encounterDoc)
    )
  else
    $.Deferred().reject()

# clear local storage relating to the current encounter
tabcat.encounter.clear = ->
  localStorage.removeItem('patientCode')
  localStorage.removeItem('encounterId')
  localStorage.removeItem('encounterNum')
  tabcat.clock.clear()



# MATH

# some simple math utilities; not TabCAT-specific

tabcat.math = {}

# return x, clamped to between min and max
tabcat.math.clamp = (min, x, max) -> Math.min(max, Math.max(min, x))

# randomly return true or false
tabcat.math.coinFlip = -> Math.random() < 0.5

# randomly return -1 or 1
tabcat.math.randomSign = -> if tabcat.math.coinFlip() then 1 else -1

# return a mod b, but always return a positive value
tabcat.math.mod = (a, b) -> ((a % b) + b) % b

# return a number chosen uniformly at random from [a, b)
tabcat.math.randomUniform = (a, b) -> a + Math.random() * (b - a)


# TASK

# recording how a patient did on a task

tabcat.task = {}

# the CouchDB document for this task
tabcat.task.doc = null


# Promise: Initialize the task. This does lots of things:
# - start automatically logging when the browser resizes
# - check if it's okay to continue (correct PHI, browser capabilities, etc)
# - create an initial task doc with start time, browser info, viewport,
#   patient code, etc.
tabcat.task.start = _.once((options) ->
  tabcat.task.doc =
      _id: tabcat.couch.randomUUID()
      type: 'task'
      browser: tabcat.task.getBrowserInfo()
      clockLastStarted: tabcat.clock.lastStarted()
      encounter: tabcat.encounter.getEncounterId()
      eventLog: tabcat.task.eventLog
      patientCode: tabcat.encounter.getPatientCode()
      startedAt: tabcat.clock.now()
      startViewport: tabcat.task.getViewportInfo()

  if not options?.examinerAdministered
    localStorage.patientHasDevice = true

  # create the task document on the server; we'll updated it when
  # tabcat.task.finish() is called. This allows us to fail fast if there's
  # a problem with the server, and also to detect tasks that were started
  # but not finished.
  createTaskDoc = (additionalFields) ->
    $.extend(tabcat.task.doc, additionalFields)
    putDoc(DB, tabcat.task.doc)

  # fetch login information and the task's design doc (.), and create
  # the task document, with some additional fields filled in
  $.when(tabcat.couch.getUser(), $.getJSON('.'), tabcat.config.get()).then(
    ([user], [designDoc], [configDoc]) ->
      fields =
        name: designDoc?.kanso.config.name
        version: designDoc?.kanso.config.version
        user: user

      if tabcat.config.canStoreLimitedPHI(configDoc)
        fields.limitedPHI =
          clockOffset: tabcat.clock.offset()

      createTaskDoc(fields)
  )
)

# automatically log whenever the viewport changes size (in tablets,
# this will be when the tablet is rotated)
$(window).resize((event) ->
  tabcat.task.logEvent(viewport: tabcat.task.getViewportInfo(), event))

# Use this instead of $(document).ready(), so that we can also wait for
# tabcat.task.start() to complete
tabcat.task.ready = (handler) ->
  $.when($.ready.promise(), tabcat.task.start()).then(handler)


# upload task info to the DB, and (TODO) load the page for the next task
tabcat.task.finish = (options) ->
  now = tabcat.clock.now()

  tabcat.task.start().then(->
    tabcat.task.doc.finishedAt = now
    if options?.interpretation
      tabcat.task.doc.interpretation = options.interpretation
    putDoc(DB, tabcat.task.doc)
  )

# get basic information about the browser. This should not change
# over the course of the task
# TODO: add screen DPI/physical size, if available
tabcat.task.getBrowserInfo = ->
  screenHeight: screen.height
  screenWidth: screen.width
  userAgent: navigator.userAgent


# get information about the viewport
tabcat.task.getViewportInfo = ->
  $w = $(window)
  return {
    left: $w.scrollLeft()
    top: $w.scrollTop()
    width: $w.width()
    height: $w.height()
  }


# a place for the task to store things the user did, along with timing
# information and the state of the task. This is independent from
# tabcat.task.start
tabcat.task.eventLog = []


# Store data in tabcat.task.eventLog about:
#
# state: the state of the world (rectangle here, intensity is 30). An object
#        in a format of your choice. (TODO: add some standard suggestions)
# event: a jQuery event that fired, or a string
# interpretation: what happened (e.g. did the user tap in the correct spot?)
# now: when the event happened, relative to start of encounter
# (i.e. tabcat.clock.now()). If not set, we try to infer this from
# event.timeStamp
#
# Stores an object with the fields event, now, interpretation, state. "event"
# is a summary of the event, "now" is the the time of the event relative to
# start of encounter (or just tabcat.clock.now() if "event" is undefined),
# and "state" and "interpretation" are stored as-is.
tabcat.task.logEvent = (state, event, interpretation, now) ->
  if not now?  # ...when?
    if event?.timeStamp
      now = event.timeStamp - tabcat.clock.offset()
    else
      now = tabcat.clock.now()

  eventLogItem = now: now

  if typeof event is 'string'
    eventLogItem.event = {type: event}
  else if event?
    eventLogItem.event = _.pick(event, 'pageX', 'pageY', 'type')

  if interpretation?
    eventLogItem.interpretation = interpretation

  if state?
    eventLogItem.state = state

  tabcat.task.eventLog.push(eventLogItem)


# UI

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



# Register a click immediately on tap/mouseup, rather than waiting for
# a double-click (requires fastclick.js)
tabcat.ui.enableFastClick = ->
  $(-> FastClick.attach(document.body))


tabcat.ui.fixAspectRatio = (element, ratio) ->
  # Ensure that *element* has the given aspect ratio (width / height),
  # and make it as large as possible within the bounds of its parent
  # element. This property will be preserved on window resize.
  #
  # We do this by setting its left, right, width, etc.
  # to the appropriate percentage. We do not set border, margin, or padding.
  #
  # This is part of how we ensure that tasks look the same on different devices.

  # TODO: handle nested elements properly (currently we'll get wrong results
  # if you call this on an element and then on its parent)

  # TODO: set max height in inches so that tests will display at the same size
  # on different devices, assuming screen is large enough. Use
  # https://github.com/tombigel/detect-zoom or something similar to determine
  # real pixel size (devices generally use a fake dpi by convention).
  element = $(element)

  fixElement = (event) ->
    parent = $(element.parent())
    parentWidth = parent.width()
    parentHeight = parent.height()
    parentRatio = parentWidth / parentHeight

    if parentRatio > ratio
      # parent is too wide, need gap on left and right
      gap = 100 * (parentRatio - ratio) / parentRatio / 2

      element.css(
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

      element.css(
        position: 'absolute'
        left: '0%'
        right: '100%'
        width: '100%'
        top: gap + '%'
        bottom: 100 - gap + '%'
        height: 100 - 2 * gap + '%'
      )

  fixElement(element)

  $(window).resize(fixElement)


# Make sure the font-size of the given element is always the given percent
# of the element's height. This will be preserved on window resize. This
# ensures we get similar text layouts on different devices.
tabcat.ui.linkFontSizeToHeight = (element, percent) ->
  element = $(element)

  fixElement = (event) ->
    # for font-size, "%" means % of default font size, not % of height.
    sizeInPx = element.height() * percent / 100
    element.css('font-size': sizeInPx + 'px')

  fixElement(element)

  $(window).resize(fixElement)


# update the encounter clock on the statusBar
tabcat.ui.updateEncounterClock = ->
  # handle end of encounter gracefully
  if tabcat.encounter.getEncounterId()?
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

# update the statusBar div, populating it if necessary
tabcat.ui.updateStatusBar = ->
  statusBar = $('#statusBar')

  # populate with new HTML if we didn't already
  if statusBar.find('div.left').length is 0
    statusBar.html(
      """
      <div class="left">
        <img class="banner" src="img/banner-white.png">
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

    statusBar.find('button.login').on('click', (event) ->
      button = $(event.target)
      if button.text() == 'Log Out'
        tabcat.ui.logout()
      else
        tabcat.ui.requestLogin()
    )

    statusBar.find('div.center').on('click', (event) ->
      window.location = '../core/encounter.html')

  tabcat.couch.getUser().then((user) ->
    emailP = statusBar.find('p.email')
    button =  statusBar.find('button.login')
    encounterP = statusBar.find('p.encounter')

    if user?
      emailP.text(user)
      button.text('Log Out')

    else
      emailP.text('not logged in')
      button.text('Log In')

    button.show()

    # don't show encounter info unless patient is logged in
    patientCode = tabcat.encounter.getPatientCode()
    if patientCode? and user?
      encounterP.text(
        'Encounter #' + tabcat.encounter.getEncounterNum() +
        ' with Patient ' + patientCode)

      if not tabcat.ui.updateStatusBar.clockInterval?
        tabcat.ui.updateStatusBar.clockInterval = window.setInterval(
          tabcat.ui.updateEncounterClock, 50)
    else
      encounterP.empty()
      if tabcat.ui.updateStatusBar.clockInterval?
        window.clearInterval(tabcat.ui.updateStatusBar.clockInterval)
      statusBar.find('p.clock').empty()
  )


# log out, warning that this will close the current e
tabcat.ui.logout = ->
  logoutAndRedirect = ->
    tabcat.couch.logout().then(->
      window.location = (
        '../core/login.html' + tabcat.ui.encodeHashJSON(message: 'Logged out'))
    )

  if tabcat.encounter.getEncounterId()?
    if window.confirm('Logging out will close the current encounter. Proceed?')
      tabcat.encounter.close().always(logoutAndRedirect)
  else
    logoutAndRedirect()


# redirect to the login page
tabcat.ui.requestLogin = (options) ->
  options ?= {}

  if not options.redirPath?
    redirPath = window.location.pathname

  window.location = (
    '../core/login.html#' +
    encodeURIComponent(JSON.stringify(options)))

# force the user to log in to this page
tabcat.ui.requireLogin = (options) ->
  options ?= {}

  tabcat.couch.getUser().then(
    ((user) ->
      if not user?
        options.message ?= 'You need to log in to view that page'
        tabcat.ui.requestLogin(options)),
    ->
      options.message ?= 'Authentication error, please try logging in again'
      tabcat.ui.requestLogin(options)
  )

# read a json from the HTML fragment
tabcat.ui.readHashJSON = ->
  try
    JSON.parse(decodeURIComponent(window.location.hash.substring(1)))
  catch error
    {}

# encode json into HTML fragment. This includes the leading "#"
tabcat.ui.encodeHashJSON = (json) ->
  return '#' + encodeURIComponent(JSON.stringify(json))


# Don't allow the document to scroll past its boundaries. This only works
# if your document isn't larger than the viewport.
tabcat.ui.turnOffBounce = ->
  $(document).bind('touchmove', (event) ->
    event.preventDefault())


# add to the global namespace
@tabcat = tabcat
