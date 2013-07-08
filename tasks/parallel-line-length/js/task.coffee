DEBUG_MODE = false

# LOOK AND FEEL

# pretend div containing the test is on an iPad
ASPECT_RATIO = 4/3

# range on line length, as a % of container width
SHORT_LINE_MIN_LENGTH = 40
SHORT_LINE_MAX_LENGTH = 50
# offest between line centers, as a % of the shorter line's length
LINE_OFFSET_AT_CENTER = 50
# number of positions for lines (currently, top and bottom of screen).
# these work with the layout-0 and layout-1 CSS classes
NUM_LAYOUTS = 2
# how long a fade should take, in msec
FADE_DURATION = FADE_DURATION


# STAIRCASING PARAMETERS

# intensity is the % the longer line is longer than the shorter one
MIN_INTENSITY = 1
MAX_INTENSITY = 50
# decrease intensity by this much after each correct response
STEPS_DOWN = 1
# increase increase by this much after each incorrect response
STEPS_UP = 3
# start practice mode here
PRACTICE_START_INTENSITY = 40
# jump to this intensity after exiting practice mode
START_INTENSITY = 15
# get this many correct in a row to leave practice mode
PRACTICE_MAX_STREAK = 4
# get this many correct in a row to turn off the practice mode instructions
PRACTICE_CAPTION_MAX_STREAK = 2
# task is done after this many reversals (change in direction of
# intensity change). Bumping against the floor/ceiling also counts
# as a reversal
MAX_REVERSALS = 10


# VARIABLES

# time of first user action (not when the page loads). Thus, time to
# complete the initial (practice) trial isn't included.
startTimestamp = null
# time user completed final trial
endTimestamp = null

intensity = PRACTICE_START_INTENSITY
# number of practice trials correct in a row
practiceStreakLength = 0
# used to track reversals. not maintained in practice mode
lastIntensityChange = 0

# intensity at each reversal. This is the data we care about.
intensitiesAtReversal = []
# how many trials completed so far (including practice trials)
numTrials = 0


# FUNCTIONS

inPracticeMode = -> practiceStreakLength < PRACTICE_MAX_STREAK

shouldShowPracticeCaption = ->
  practiceStreakLength < PRACTICE_CAPTION_MAX_STREAK

taskIsDone = -> intensitiesAtReversal.length >= MAX_REVERSALS


# call this when the user taps on a line. correct is a boolean
# this will update practiceStreakLength, intensity, lastIntensityChange,
# and intensitiesAtReversal
registerResult = (event) ->
  correct = event.data.isLonger

  state = getTaskState()

  if startTimestamp is null
    startTimestamp = $.now()

  change = if correct then -STEPS_DOWN else STEPS_UP

  lastIntensity = intensity
  intensity = tabcat.math.clamp(
    MIN_INTENSITY, lastIntensity + change, MAX_INTENSITY)
  intensityChange = intensity - lastIntensity

  interpretation =
    correct: correct
    intensityChange: change

  if inPracticeMode()
    if correct
      practiceStreakLength += 1
      if not inPracticeMode()  # i.e. we just left practice mode
        intensity = START_INTENSITY
        lastIntensityChange = 0
    else
      practiceStreakLength = 0
  else
    wasReversal = (intensityChange * lastIntensityChange < 0 or
                   intensityChange is 0)
    interpretation.reversal = wasReversal
    if wasReversal
      intensitiesAtReversal.push(lastIntensity)
    lastIntensityChange = intensityChange

  tabcat.task.logEvent(state, event, interpretation)

  numTrials += 1


# generate data, including CSS, for the next trial
getNextTrial = ->
  shortLineLength = tabcat.math.randomUniform(SHORT_LINE_MIN_LENGTH,
                                              SHORT_LINE_MAX_LENGTH)

  longLineLength = shortLineLength * (1 + intensity / 100)

  if tabcat.math.coinFlip()
    [topLineLength, bottomLineLength] = [shortLineLength, longLineLength]
  else
    [bottomLineLength, topLineLength] = [shortLineLength, longLineLength]

  centerOffset = shortLineLength * LINE_OFFSET_AT_CENTER / 100

  # make sure both lines are the same distance from the edge of the screen
  totalWidth = topLineLength / 2 + bottomLineLength / 2 + centerOffset
  margin = (100 - totalWidth) / 2

  # push one line to the right, and one to the left
  if tabcat.math.coinFlip()
    topLineLeft = margin
    bottomLineLeft = 100 - margin - bottomLineLength
  else
    topLineLeft = 100 - margin - topLineLength
    bottomLineLeft = margin

  return {
    topLine:
      css:
        left: topLineLeft + '%'
        width: topLineLength + '%'
      isLonger: topLineLength >= bottomLineLength
    bottomLine:
      css:
        left: bottomLineLeft + '%'
        width: bottomLineLength + '%'
      isLonger: bottomLineLength >= topLineLength
    shortLineLength: shortLineLength
    intensity: intensity
  }


# event handler for clicks on lines. either fade in the next trial,
# or call finishTask()
showNextTrial = (event) ->
  if event and event.data
    registerResult(event)

  if taskIsDone()
    tabcat.task.finish()
  else
    nextTrialDiv = getNextTrialDiv()
    $('#task-main').empty()
    $('#task-main').append(nextTrialDiv)
    tabcat.ui.fixAspectRatio(nextTrialDiv, ASPECT_RATIO)
    tabcat.ui.linkEmToPercentOfHeight(nextTrialDiv)
    $(nextTrialDiv).fadeIn({duration: FADE_DURATION})


# create the next trial, and return the div containing it, but don't
# show it or add it to the page (showNextTrial() does this)
getNextTrialDiv = ->
  # get line offsets and widths for next trial
  trial = getNextTrial()

  # construct divs for these lines
  topLineDiv = $('<div></div>', {'class': 'line top-line'})
  topLineDiv.css(trial.topLine.css)
  topLineDiv.bind('click', trial.topLine, showNextTrial)

  bottomLineDiv = $('<div></div>', {'class': 'line bottom-line'})
  bottomLineDiv.css(trial.bottomLine.css)
  bottomLineDiv.bind('click', trial.bottomLine, showNextTrial)

  if (DEBUG_MODE)
    shortLineDiv = (
      if trial.topLine.isLonger then bottomLineDiv else topLineDiv)
    shortLineDiv.text(trial.shortLineLength.toFixed(2) +
      '% of screen width')

    longLineDiv = (
      if trial.topLine.isLonger then topLineDiv else bottomLineDiv)
    longLineDiv.text(trial.intensity + '% longer than short line')

  # put them in an offscreen div
  containerDiv = $(
    '<div></div>', {
    'class': 'layout-' + numTrials % NUM_LAYOUTS})
  $(containerDiv).hide()
  containerDiv.append(topLineDiv, bottomLineDiv)
  containerDiv.bind('click', catchStrayClick)

  # show practice caption, if required
  if shouldShowPracticeCaption()
    practiceCaptionDiv = $('<div></div>',
      {'class': 'practice-caption'})
    practiceCaptionDiv.html('Tap the longer line<br>' +
      ' quickly and accurately.')
    containerDiv.append(practiceCaptionDiv)

  return containerDiv


# summary of the current state of the task
getTaskState = ->
  lines: (getElementBounds(div) for div in $('div.line:visible'))
  intensity: intensity
  practiceCaption: shouldShowPracticeCaption()
  practiceMode: inPracticeMode()
  trial: numTrials


getElementBounds = (element) ->
  # some browsers include height and width, but it's redundant
  _.pick(element.getBoundingClientRect(), 'top', 'bottom', 'left', 'right')


catchStrayClick = (event) ->
  tabcat.task.logEvent(getTaskState(), event)



# INITIALIZATION

tabcat.task.start()

tabcat.ui.enableFastClick()
tabcat.ui.turnOffBounce()

tabcat.ui.linkEmToPercentOfHeight()

tabcat.task.ready(showNextTrial)
