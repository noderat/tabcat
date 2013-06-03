DEBUG_MODE = false

# LOOK AND FEEL

# css depends on 1em being this % of container height
FONT_HEIGHT_PERCENT = 2
# pretend div containing the test is on an iPad
ASPECT_RATIO = 4/3
# max rotation of the target line
MAX_TARGET_ROTATION = 50
# minimum difference in orientation between trials
MIN_ORIENTATION_DIFFERENCE = 20

# how long a fade should take, in msec
FADE_DURATION = FADE_DURATION


# STAIRCASING PARAMETERS

# intensity is the difference in angle between the correct line and the
# skewed one
MIN_INTENSITY = 1
MAX_INTENSITY = 89
# decrease intensity by this much after each correct response
STEPS_DOWN = 1
# increase increase by this much after each incorrect response
STEPS_UP = 3
# start practice mode here
PRACTICE_START_INTENSITY = 45
# jump to this intensity after exiting practice mode
START_INTENSITY = 15
# get this many correct in a row to leave practice mode
PRACTICE_MAX_STREAK = 4
# get this many correct in a row to turn off the practice mode instructions
PRACTICE_CAPTION_MAX_STREAK = 2
# task is done after this many reversals (change in direction of
# intensity change). Bumping against the floor/ceiling also counts
# as a reversal
MAX_REVERSALS = 20


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

lastOrientation = 0

inPracticeMode = -> practiceStreakLength < PRACTICE_MAX_STREAK

shouldShowPracticeCaption = ->
  practiceStreakLength < PRACTICE_CAPTION_MAX_STREAK

taskIsDone = -> intensitiesAtReversal.length >= MAX_REVERSALS


# call this when the user taps on a line. correct is a boolean
# this will update practiceStreakLength, intensity, lastIntensityChange,
# and intensitiesAtReversal
registerResult = (correct) ->
  if startTimestamp is null
    startTimestamp = $.now()

  change = if correct then -STEPS_DOWN else STEPS_UP

  lastIntensity = intensity
  intensity = tabcat.math.clamp(
    MIN_INTENSITY, lastIntensity + change, MAX_INTENSITY)
  intensityChange = intensity - lastIntensity

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
    if wasReversal
      intensitiesAtReversal.push(lastIntensity)
    lastIntensityChange = intensityChange

  numTrials += 1


# generate data, including CSS, for the next trial
getNextTrial = ->
  targetOrientation = getNextOrientation()

  skew = intensity * tabcat.math.randomSign()

  [line1Skew, line2Skew] = _.shuffle([skew, 0])

  return {
    targetLine:
      orientation: targetOrientation
    line1:
      skew: line1Skew
    line2:
      skew: line2Skew
  }


# pick a new orientation that's not too close to the last one
getNextOrientation = ->
  while true
    orientation = tabcat.math.randomUniform(-MAX_TARGET_ROTATION,
                                            MAX_TARGET_ROTATION)
    if Math.abs(orientation - lastOrientation) >= MIN_ORIENTATION_DIFFERENCE
      lastOrientation = orientation
      return orientation


# event handler for clicks on lines. either fade in the next trial,
# or call finishTask()
showNextTrial = (event) ->
  if event and event.data
    registerResult(event.data.skew == 0)

  if taskIsDone()
    finishTask()
  else
    nextTrialDiv = getNextTrialDiv()
    $('#task-main').empty()
    $('#task-main').append(nextTrialDiv)
    tabcat.ui.fixAspectRatio(nextTrialDiv, ASPECT_RATIO)
    tabcat.ui.linkFontSizeToHeight(nextTrialDiv, FONT_HEIGHT_PERCENT)
    $(nextTrialDiv).fadeIn({duration: FADE_DURATION})


# show the "Done!" page, and enable its "show scoring" button
finishTask = (event) ->
  endTimestamp = $.now()

  $('#scoring .score-list').text(intensitiesAtReversal.join(', '))
  elapsedSecs = (endTimestamp - startTimestamp) / 1000
  # we start timing after the first click, so leave out the first
  # trial in timing info
  $('#scoring .elapsed-time').text(
    elapsedSecs.toFixed(1) + 's / ' + (numTrials - 1) + ' = ' +
    (elapsedSecs / (numTrials - 1)).toFixed(1) + 's')

  $('#task').hide()
  $('#done').fadeIn({duration: FADE_DURATION})

  $('#show-scoring').bind('click', showScoring)
  $('#show-scoring').removeAttr('disabled')


# show the scoring page
showScoring = (event) ->
  $('#done').hide()
  $('#scoring').fadeIn({duration: FADE_DURATION})


# create the next trial, and return the div containing it, but don't
# show it or add it to the page (showNextTrial() does this)
getNextTrialDiv = ->
  # get line offsets and widths for next trial
  trial = getNextTrial()

  # construct divs for these lines
  targetLineDiv = $('<div></div>', {class: 'line target-line'})

  line1Div = $('<div></div>', {class: 'line line-1'})
  line1Div.css(rotationCss(trial.line1.skew))
  line1Div.bind('click', trial.line1, showNextTrial)

  line2Div = $('<div></div>', {class: 'line line-2'})
  line2Div.css(rotationCss(trial.line2.skew))
  line2Div.bind('click', trial.line2, showNextTrial)

  # put them in a container, and rotate it
  containerDiv = $('<div></div>', {class: 'line-container'})
  containerDiv.css(rotationCss(trial.targetLine.orientation))
  containerDiv.append(targetLineDiv, line1Div, line2Div)

  # put them in an offscreen div
  trialDiv = $('<div></div>')
  $(trialDiv).hide()
  trialDiv.append(containerDiv)

  # show practice caption, if required
  if shouldShowPracticeCaption()
    practiceCaptionDiv = $('<div></div>',
      {'class': 'practice-caption'})
    practiceCaptionDiv.html(
      'Which is parallel to the <span class="target">blue</span> line?')
    trialDiv.append(practiceCaptionDiv)

  return trialDiv


rotationCss = (angle) ->
  if angle == 0
    return {}

  value = 'rotate(' + angle + 'deg)'
  return {
    transform: value
    '-moz-transform': value
    '-ms-transform': value
    '-o-transform': value
    '-webkit-transform': value
  }



# INITIALIZATION

tabcat.ui.enableFastClick()
tabcat.ui.turnOffBounce()

tabcat.ui.linkFontSizeToHeight($(document.body), FONT_HEIGHT_PERCENT)

showNextTrial()
