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

# LOOK AND FEEL

# pretend div containing the test is on an iPad
ASPECT_RATIO = 4/3

# range on line length, as a % of container width
SHORT_LINE_MIN_LENGTH = 40
SHORT_LINE_MAX_LENGTH = 50
# offset between line centers, as a % of the shorter line's length
LINE_OFFSET_AT_CENTER = 50
# how much wider to make invisible target around lines, as % of width
TARGET_BORDER_WIDTH = 3 / ASPECT_RATIO
# number of positions for lines (currently, top and bottom of screen).
# these work with the parallelLineLayout0 and parallelLineLayout1 CSS classes
NUM_LAYOUTS = 2
# how long a fade should take, in msec
FADE_DURATION = 400


# TASK PARAMETERS

# jump to this intensity after exiting practice mode
START_INTENSITY = 15
# get this many correct in a row to leave practice mode
PRACTICE_MAX_STREAK = 4
# get this many correct in a row to turn off the practice mode instructions
PRACTICE_CAPTION_MAX_STREAK = 2
# task is done after this many reversals (change in direction of
# intensity change). Bumping against the floor/ceiling also counts
# as a reversal
MAX_REVERSALS = 14


# VARIABLES

staircase = new tabcat.task.Staircase(
  intensity: 40
  minIntensity: 1
  maxIntensity: 50
  stepsUp: 3
  stepsDown: 1
)

practiceStreakLength = 0


# FUNCTIONS

inPracticeMode = -> practiceStreakLength < PRACTICE_MAX_STREAK

shouldShowPracticeCaption = ->
  practiceStreakLength < PRACTICE_CAPTION_MAX_STREAK


# call this when the user taps on a line. Updates staircase
registerResult = (event) ->
  state = getTaskState()

  correct = event.data.isLonger

  interpretation = staircase.addResult(
    correct, ignoreReversals: inPracticeMode())

  if inPracticeMode()
    if correct
      practiceStreakLength += 1
      if not inPracticeMode()  # i.e. we just left practice mode
        # initialize the real trial
        staircase.intensity = START_INTENSITY
        staircase.lastIntensityChange = 0
    else
      practiceStreakLength = 0

  tabcat.task.logEvent(state, event, interpretation)


# generate data, including CSS, for the next trial
getNextTrial = ->
  shortLineLength = tabcat.math.randomUniform(SHORT_LINE_MIN_LENGTH,
                                              SHORT_LINE_MAX_LENGTH)

  longLineLength = shortLineLength * (1 + staircase.intensity / 100)

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
      targetCss:
        left: topLineLeft - TARGET_BORDER_WIDTH + '%'
        width: topLineLength + TARGET_BORDER_WIDTH * 2 + '%'
    bottomLine:
      css:
        left: bottomLineLeft + '%'
        width: bottomLineLength + '%'
      isLonger: bottomLineLength >= topLineLength
      targetCss:
        left: bottomLineLeft - TARGET_BORDER_WIDTH + '%'
        width: bottomLineLength + TARGET_BORDER_WIDTH * 2 + '%'
    shortLineLength: shortLineLength
    intensity: staircase.intensity
  }


# event handler for taps on lines. Either fade in the next trial or
# call tabcat.task.finish()
handleTapOnLine = (event) ->
  event.preventDefault()
  registerResult(event)

  if staircase.numReversals >= MAX_REVERSALS
    tabcat.task.finish()
  else
    showNextTrial()

  return


# event handler for taps on lines. either fade in the next trial or
# call tabcat.task.finish()
showNextTrial = ->
  $nextTrialDiv = getNextTrialDiv()
  $('#task').empty()
  $('#task').append($nextTrialDiv)
  tabcat.ui.fixAspectRatio($nextTrialDiv, ASPECT_RATIO)
  tabcat.ui.linkEmToPercentOfHeight($nextTrialDiv)
  $nextTrialDiv.fadeIn(duration: FADE_DURATION)


# create the next trial, and return the (jQuery-wrapped) div containing it, but
# don't show it or add it to the page (showNextTrial() does this)
getNextTrialDiv = ->
  # get line offsets and widths for next trial
  trial = getNextTrial()

  # construct divs for these lines
  $topLineDiv = $('<div></div>', class: 'line topLine')
  $topLineDiv.css(trial.topLine.css)
  $topLineTargetDiv = $('<div></div>', class: 'lineTarget topLineTarget')
  $topLineTargetDiv.css(trial.topLine.targetCss)
  $topLineTargetDiv.on(
    'mousedown touchstart', trial.topLine, handleTapOnLine)

  $bottomLineDiv = $('<div></div>', class: 'line bottomLine')
  $bottomLineDiv.css(trial.bottomLine.css)
  $bottomLineTargetDiv = $(
    '<div></div>', class: 'lineTarget bottomLineTarget')
  $bottomLineTargetDiv.css(trial.bottomLine.targetCss)
  $bottomLineTargetDiv.on(
    'mousedown touchstart', trial.bottomLine, handleTapOnLine)

  # put them in an offscreen div
  $containerDiv = $('<div></div>',
    class: 'parallelLineLayout' + staircase.trialNum % NUM_LAYOUTS)
  $containerDiv.hide()
  $containerDiv.append(
    $topLineDiv, $topLineTargetDiv, $bottomLineDiv, $bottomLineTargetDiv)
  $containerDiv.on('mousedown touchstart', catchStrayTouchStart)

  # show practice caption, if required
  if shouldShowPracticeCaption()
    $practiceCaptionDiv = $('<div></div>', class: 'practiceCaption')
    $practiceCaptionDiv.html('Tap the longer line<br>' +
      ' quickly and accurately.')
    $containerDiv.append($practiceCaptionDiv)

  return $containerDiv


# summary of the current state of the task
getTaskState = ->
  state =
    intensity: staircase.intensity
    stimuli: getStimuli()
    trialNum: staircase.trialNum

  if inPracticeMode()
    state.practiceMode = true

  return state


# describe what's on the screen. helper for getTaskState()
getStimuli = ->
  stimuli =
    lines: (tabcat.task.getElementBounds(div) for div in $('div.line:visible'))

  $practiceCaption = $('div.practiceCaption:visible')
  if $practiceCaption.length > 0
    stimuli.practiceCaption = tabcat.task.getElementBounds($practiceCaption[0])

  return stimuli

catchStrayTouchStart = (event) ->
  event.preventDefault()
  tabcat.task.logEvent(getTaskState(), event)


# INITIALIZATION
@initTask = ->
  tabcat.task.start(trackViewport: true)

  tabcat.ui.turnOffBounce()

  tabcat.ui.requireLandscapeMode($('#task'))

  $(showNextTrial)
