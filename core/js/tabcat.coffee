# GLOBALS

tabcat = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# STUFF THAT SHOULD BE IN JQUERY

jQuery.extend(
  putJSON: (url, data, success) ->
    jQuery.ajax(
      contentType: 'application/json'
      data: JSON.stringify(data)
      success: success
      type: 'PUT'
      url: url
    )
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
  startAt = startAt or 0
  localStorage.clockLastStarted = startAt
  localStorage.clockOffset = $.now() - startAt
  return  # don't let people depend on return value

# Start the clock, if it's not already started
tabcat.clock.start = (startAt) ->
  if not (localStorage.clockLastStarted and localStorage.clockOffset)
    tabcat.clock.reset()


# COUCH

# extra utilities for couchDB

tabcat.couch = {}

# create a random UUID. Do this instead of $.couch.newUUID(); it makes sure
# we don't put timestamps in UUIDs, and works offline.
tabcat.couch.randomUUID = () ->
  (Math.floor(Math.random() * 16).toString(16) for _ in [0..31]).join('')

TABCAT_ROOT = '/tabcat/'
DB_ROOT = '/tabcat-data/'

# quick wrapper to make failure callbacks that do something useful on 404.
# define failFilter to handle failures other than 404s; otherwise the error
# will be passed through
on404 = (callback, failFilter) ->
  (xhr, args...) ->
    if xhr.status == 404
      callback()
    else if failFilter
      failFilter(xhr, args...)
    else
      # pass error through
      xhr


# ENCOUNTER

# logic for creating patients and opening encounters with them.

tabcat.encounter = {}

# start an encounter. This involves network access, so this method
# returns a promise. Sample usage:
#
# tabcat.encounter.start(patientCode).then(
#   (patientDoc) -> ... # proceed,
#   (xhr) -> ... # show error message on failure)
tabcat.encounter.start = (patientCode) ->
  patientCode = patientCode or 0
  patientDocId = 'patient-' + patientCode

  # this adds an encounter to patientDoc.encounters in the DB, and then
  # updates local storage
  addEncounterToPatientDoc = (patientDoc) ->
    if not patientDoc.encounters
      patientDoc.encounters = []

    encounter =
      id: tabcat.couch.randomUUID()
      year: (new Date).getFullYear()

    patientDoc.encounters.push(encounter)

    $.putJSON(DB_ROOT + patientDoc._id, patientDoc).then(->
      tabcat.clock.reset()
      localStorage.patientCode = patientCode
      localStorage.encounterId = encounter.id
      # encounterNum is used by the UI only; the patient document is
      # the canonical way to tell the order of encounters
      localStorage.encounterNum = patientDoc.encounters.length
      return patientDoc
    )

  # get/create the patient doc, add the encounter, update local storage
  $.getJSON(DB_ROOT + patientDocId).then(
    addEncounterToPatientDoc,
    on404(-> addEncounterToPatientDoc(_id: patientDocId, type: 'patient'))
  )


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

# get basic information about the browser. This should not change
# over the course of the task
# TODO: add screen DPI/physical size, if available
tabcat.task.getBrowserInfo = -> {
  screenHeight: screen.height
  screenWidth: screen.width
  userAgent: navigator.userAgent
}


# get information about the viewport: [offsetX, offsetY, width, height]
tabcat.task.getViewportInfo = ->
  $w = $(window)
  return {
    left: $w.scrollLeft()
    top: $w.scrollTop()
    width: $w.width()
    height: $w.height()
  }


tabcat.task.eventLog = []

# Store data in tabcat.task.eventLog about:
#
# state: the state of the world (rectangle here, intensity is 30). An object
#        in a format of your choice. (TODO: add some standard suggestions)
# event: a jQuery event that fired
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
  if not now  # ...when?
    if event.timeStamp
      now = event.timeStamp - tabcat.clock.offset()
    else
      now = tabcat.clock.now()

  eventData = null
  if event
    eventData =
      pageX: event.pageX
      pageY: event.pageY
      type: event.type

  tabcat.task.eventLog.push(
    event: eventData
    interpretation: interpretation
    now: now
    state: state
  )


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

      element.css({
        position: 'absolute'
        left: gap + '%'
        right: 100 - gap + '%'
        width: 100 - 2 * gap + '%'
        top: '0%'
        bottom: '100%'
        height: '100%'
      })
    else
      # parent is too narrow, need gap on top and bottom
      gap = (100 * (1 / parentRatio - 1 / ratio) * parentRatio / 2)

      element.css({
        position: 'absolute'
        left: '0%'
        right: '100%'
        width: '100%'
        top: gap + '%'
        bottom: 100 - gap + '%'
        height: 100 - 2 * gap + '%'
      })

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
    element.css({'font-size': sizeInPx + 'px'})

  fixElement(element)

  $(window).resize(fixElement)


# Don't allow the document to scroll past its boundaries. This only works
# if your document isn't larger than the viewport.
tabcat.ui.turnOffBounce = ->
  $(document).bind('touchmove', (event) ->
    event.preventDefault())


# add to the global namespace
@tabcat = tabcat
