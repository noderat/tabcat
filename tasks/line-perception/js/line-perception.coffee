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

# abstract base class for line perception tasks
LinePerceptionTask = class

  # aspect ratio for the task
  ASPECT_RATIO: 4 / 3  # match iPad

  # how long a fade should take, in msec
  FADE_DURATION: 400

  # minimum intensity for task
  MIN_INTENSITY: 1

  # max intensity for task (set in subclasses)
  #MAX_INTENSITY: null

  # task is done after this many reversals (change in direction of
  # intensity change). Bumping against the floor/ceiling also counts
  # as a reversal
  MAX_REVERSALS: 14

  # get this many correct in a row to turn off the practice mode instructions
  PRACTICE_CAPTION_MAX_STREAK: 2

  # get this many correct in a row to leave practice mode
  PRACTICE_MAX_STREAK: 4

  # start practice mode here (set in subclasses)
  #PRACTICE_START_INTENSITY: null

  # start intensity of the real task here
  #START_INTENSITY: null

  # decrease intensity by this much when correct
  STEPS_DOWN: 1

  # increase intensity by this much when incorrect
  STEPS_UP: 3

  constructor: ->
    @practiceStreakLength = 0

    @staircase = new tabcat.task.Staircase(
      intensity: @PRACTICE_START_INTENSITY
      minIntensity: @MIN_INTENSITY
      maxIntensity: @MAX_INTENSITY
      stepsDown: @STEPS_DOWN
      stepsUp: @STEPS_UP
    )

  # call this to show the task onscreen
  start: ->
    tabcat.task.start(trackViewport: true)
    tabcat.ui.turnOffBounce()

    $(=>
      tabcat.ui.requireLandscapeMode($('#task'))
      $('#task').on('mousedown touchstart', @handleStrayTouchStart)
      @showNextTrial()
    )

  # show the next trial for the task
  showNextTrial: ->
    $nextTrialDiv = @getNextTrialDiv()
    $('#task').empty()
    $('#task').append($nextTrialDiv)
    tabcat.ui.fixAspectRatio($nextTrialDiv, @ASPECT_RATIO)
    tabcat.ui.linkEmToPercentOfHeight($nextTrialDiv)
    $nextTrialDiv.fadeIn(duration: @FADE_DURATION)

  # event handler for taps on lines
  handleLineTouchStart: (event) =>
    event.preventDefault()
    event.stopPropagation()

    state = @getTaskState()

    correct = event.data.correct

    interpretation = @staircase.addResult(
      correct, ignoreReversals: @inPracticeMode())

    if @inPracticeMode()
      if correct
        @practiceStreakLength += 1
        if not @inPracticeMode()  # i.e. we just left practice mode
          # initialize the real trial
          @staircase.intensity = @START_INTENSITY
          @staircase.lastIntensityChange = 0
      else
        @practiceStreakLength = 0

    tabcat.task.logEvent(state, event, interpretation)

    if @staircase.numReversals >= @MAX_REVERSALS
      tabcat.task.finish()
    else
      @showNextTrial()

    return

  # event handler for taps that miss the lines
  handleStrayTouchStart: (event) =>
    event.preventDefault()
    tabcat.task.logEvent(@getTaskState(), event)
    return

  # redefine this in your subclass, to show the stimuli for the task
  getNextTrialDiv: ->
    throw new Error("not defined")

  # get the current state of the task (for event logging)
  getTaskState: ->
    state =
      intensity: @staircase.intensity
      stimuli: @getStimuli()
      trialNum: @staircase.trialNum

    if @inPracticeMode()
      state.practiceMode = true

    return state

  # helper for getTaskState. You'll probably want to add additional fields
  # in your subclass
  getStimuli: ->
    stimuli = {}

    $practiceCaption = $('div.practiceCaption')
    if $practiceCaption.is(':visible')
      stimuli.practiceCaption = tabcat.task.getElementBounds(
        $practiceCaption[0])

    return stimuli

  # are we in practice mode?
  inPracticeMode: ->
    @practiceStreakLength < @PRACTICE_MAX_STREAK

  # should we show the practice mode caption?
  shouldShowPracticeCaption: ->
    @practiceStreakLength < @PRACTICE_CAPTION_MAX_STREAK




# abstract base class for line length tasks
LineLengthTask = class extends LinePerceptionTask

  # width of lines, as % of height
  LINE_WIDTH: 7

  # start practice mode here
  PRACTICE_START_INTENSITY: 40

  # range on line length, as a % of container width
  SHORT_LINE_RANGE: [40, 50]

  # start real task here
  START_INTENSITY: 15

  # how much wider to make invisible target around lines, as a % of height
  TARGET_BORDER: 3

  # now with line bounding boxes!
  getStimuli: ->
    _.extend(super(),
      lines: (
        tabcat.task.getElementBounds(div) for div in $('div.line:visible'))
    )


# PARALLEL LINE LENGTH

@ParallelLineLengthTask = class extends LineLengthTask

  # number of positions for lines (currently, top and bottom of screen).
  # these work with the parallelLineLayout0 and parallelLineLayout1 CSS classes
  NUM_LAYOUTS: 2

  # offset between line centers, as a % of the shorter line's length
  LINE_OFFSET_AT_CENTER: 50

  getNextTrialDiv: ->
    # get line offsets and widths for next trial
    trial = @getNextTrial()

    # construct divs for these lines
    $topLineDiv = $('<div></div>', class: 'line topLine')
    $topLineDiv.css(trial.topLine.css)
    $topLineTargetDiv = $('<div></div>', class: 'lineTarget topLineTarget')
    $topLineTargetDiv.css(trial.topLine.targetCss)
    $topLineTargetDiv.on(
      'mousedown touchstart', trial.topLine, @handleLineTouchStart)

    $bottomLineDiv = $('<div></div>', class: 'line bottomLine')
    $bottomLineDiv.css(trial.bottomLine.css)
    $bottomLineTargetDiv = $(
      '<div></div>', class: 'lineTarget bottomLineTarget')
    $bottomLineTargetDiv.css(trial.bottomLine.targetCss)
    $bottomLineTargetDiv.on(
      'mousedown touchstart', trial.bottomLine, @handleLineTouchStart)

    # put them in an offscreen div
    layoutNum = @staircase.trialNum % @NUM_LAYOUTS
    $containerDiv = $('<div></div>', class: 'parallelLineLayout' + layoutNum)
    $containerDiv.hide()
    $containerDiv.append(
      $topLineDiv, $topLineTargetDiv, $bottomLineDiv, $bottomLineTargetDiv)

    # show practice caption, if required
    if @shouldShowPracticeCaption()
      $practiceCaptionDiv = $('<div></div>', class: 'practiceCaption')
      $practiceCaptionDiv.html('Tap the longer line<br>' +
        ' quickly and accurately.')
      $containerDiv.append($practiceCaptionDiv)

    return $containerDiv

  # generate data, including CSS, for the next trial
  getNextTrial: ->
    shortLineLength = tabcat.math.randomUniform(@SHORT_LINE_RANGE...)

    longLineLength = shortLineLength * (1 + @staircase.intensity / 100)

    [topLineLength, bottomLineLength] = _.shuffle(
      [shortLineLength, longLineLength])

    centerOffset = shortLineLength * @LINE_OFFSET_AT_CENTER / 100

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

    targetBorderWidth = @TARGET_BORDER / @ASPECT_RATIO

    return {
      topLine:
        css:
          left: topLineLeft + '%'
          width: topLineLength + '%'
        correct: topLineLength >= bottomLineLength
        targetCss:
          left: topLineLeft - targetBorderWidth + '%'
          width: topLineLength + targetBorderWidth * 2 + '%'
      bottomLine:
        css:
          left: bottomLineLeft + '%'
          width: bottomLineLength + '%'
        correct: bottomLineLength >= topLineLength
        targetCss:
          left: bottomLineLeft - targetBorderWidth + '%'
          width: bottomLineLength + targetBorderWidth * 2 + '%'
      shortLineLength: shortLineLength
      intensity: @staircase.intensity
    }


@PerpendicularLineLengthTask = class extends LineLengthTask

  # fit in a square, so all orientations work the same
  ASPECT_RATIO: 1 / 1
