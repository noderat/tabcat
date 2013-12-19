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
# max rotation of the reference line
MAX_ROTATION = 60
# minimum difference in orientation between trials
MIN_ORIENTATION_DIFFERENCE = 20
# min orientation in practice mode (to avoid the caption)
MIN_PRACTICE_MODE_ORIENTATION = 25
# how long a fade should take, in msec
FADE_DURATION = 400


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
MAX_REVERSALS = 14


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

# number of reversals so far
numReversals = 0
# which trial we're on (0-indexed)
trialNum = 0

# state of the current trial (set by getNextTrial())
currentStimuli = null


# FUNCTIONS

lastOrientation = 0

inPracticeMode = -> practiceStreakLength < PRACTICE_MAX_STREAK

shouldShowPracticeCaption = ->
  practiceStreakLength < PRACTICE_CAPTION_MAX_STREAK


# call this when the user taps on a line. correct is a boolean
# this will update practiceStreakLength, intensity, lastIntensityChange,
# and numReversals
registerResult = (event) ->
  state = getTaskState()

  correct = (event.data.skew is 0)

  change = if correct then -STEPS_DOWN else STEPS_UP

  lastIntensity = intensity
  intensity = tabcat.math.clamp(
    MIN_INTENSITY, lastIntensity + change, MAX_INTENSITY)
  intensityChange = intensity - lastIntensity

  interpretation =
    correct: correct
    intensityChange: intensityChange

  if inPracticeMode()
    if correct
      practiceStreakLength += 1
      if not inPracticeMode()  # i.e. we just left practice mode
        intensity = START_INTENSITY
        lastIntensityChange = 0
    else
      practiceStreakLength = 0
  else
    wasReversal = (
      intensityChange * lastIntensityChange < 0 or
      intensityChange is 0)  # i.e. we hit the floor/ceiling

    if wasReversal
      numReversals += 1
      interpretation.reversal = true

    lastIntensityChange = intensityChange

  tabcat.task.logEvent(state, event, interpretation)

  trialNum += 1


# generate data, including CSS, for the next trial
getNextTrial = ->
  orientation = getNextOrientation()

  skew = intensity * tabcat.math.randomSign()

  [line1Skew, line2Skew] = _.shuffle([skew, 0])

  # return this and store in currentStimuli (it's hard to query the browser
  # about rotations)
  currentStimuli =
    referenceLine:
      orientation: orientation
    line1:
      skew: line1Skew
    line2:
      skew: line2Skew


# pick a new orientation that's not too close to the last one
getNextOrientation = ->
  while true
    orientation = tabcat.math.randomUniform(-MAX_ROTATION, MAX_ROTATION)
    if Math.abs(orientation - lastOrientation) < MIN_ORIENTATION_DIFFERENCE
      continue

    if shouldShowPracticeCaption() and (
      Math.abs(orientation) < MIN_PRACTICE_MODE_ORIENTATION)
      continue

    lastOrientation = orientation
    return orientation


# event handler for taps on lines. either fade in the next trial or
# call tabcat.task.finish()
showNextTrial = (event) ->
  # don't emulate mousedown event if we get a touch event
  if event?.preventDefault?
    event.preventDefault()

  if event?.data?
    registerResult(event)

  if numReversals >= MAX_REVERSALS
    interpretation =
      intensitiesAtReversal: e.state.intensity \
        for e in tabcat.task.getEventLog() \
        when e.interpretation?.reversal
    tabcat.task.finish(interpretation: interpretation)
  else
    $nextTrialDiv = getNextTrialDiv()
    $('#task').empty()
    $('#task').append($nextTrialDiv)
    tabcat.ui.fixAspectRatio($nextTrialDiv, ASPECT_RATIO)
    tabcat.ui.linkEmToPercentOfHeight($nextTrialDiv)
    $nextTrialDiv.fadeIn(duration: FADE_DURATION)

# create the next trial, and return the div containing it, but don't
# show it or add it to the page (showNextTrial() does this)
getNextTrialDiv = ->
  # get line offsets and widths for next trial
  trial = getNextTrial()

  # construct divs for these lines
  $referenceLineDiv = $('<div></div>', class: 'referenceLine')

  $line1Div = $('<div></div>', class: 'line1')
  $line1Div.css(rotationCss(trial.line1.skew))
  $line1TargetAreaDiv = $('<div></div>', class: 'line1Target')
  $line1TargetAreaDiv.css(rotationCss(trial.line1.skew))
  $line1TargetAreaDiv.bind('mousedown touchstart', trial.line1, showNextTrial)

  $line2Div = $('<div></div>', class: 'line2')
  $line2Div.css(rotationCss(trial.line2.skew))
  $line2TargetAreaDiv = $('<div></div>', class: 'line2Target')
  $line2TargetAreaDiv.css(rotationCss(trial.line2.skew))
  $line2TargetAreaDiv.bind('mousedown touchstart', trial.line2, showNextTrial)

  # put them in a container, and rotate it
  $stimuliDiv = $('<div></div>', class: 'lineOrientationStimuli')
  $stimuliDiv.css(rotationCss(trial.referenceLine.orientation))
  $stimuliDiv.append(
    $referenceLineDiv,
    $line1Div, $line1TargetAreaDiv,
    $line2Div, $line2TargetAreaDiv)
  $stimuliDiv.bind('mousedown touchstart', catchStrayTouchStart)

  # put them in an offscreen div
  $trialDiv = $('<div></div>')
  $trialDiv.hide()

  # show practice caption, if required
  if shouldShowPracticeCaption()
    $practiceCaptionDiv = $('<div></div>', class: 'practiceCaption')
    $practiceCaptionDiv.html(
      'Which is parallel to the <span class="blue">blue</span> line?')
    $trialDiv.append($practiceCaptionDiv)

  $trialDiv.append($stimuliDiv)

  return $trialDiv


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

# summary of the current state of the task
getTaskState = ->
  state =
    intensity: intensity
    stimuli: getStimuli()
    trialNum: trialNum

  if inPracticeMode()
    state.practiceMode = true

  return state


# describe what's on the screen. helper for getTaskState()
getStimuli = ->
  stimuli = currentStimuli

  $practiceCaption = $('div.practiceCaption:visible')
  if $practiceCaption.length > 0
    stimuli = $.extend(
      {}, stimuli,
      practiceCaption: tabcat.task.getElementBounds($practiceCaption[0]))

  return stimuli


catchStrayTouchStart = (event) ->
  tabcat.task.logEvent(getTaskState(), event)



# INITIALIZATION
@initTask = ->
  tabcat.task.start(trackViewport: true)

  tabcat.ui.turnOffBounce()

  tabcat.ui.requireLandscapeMode($('#task'))

  $(showNextTrial)
