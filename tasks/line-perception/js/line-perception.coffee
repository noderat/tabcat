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
translations =
  en:
    translation:
      tap_the_longer_line_html:
        'Tap the longer line<br>quickly and accurately.'
      which_is_parallel_html:
        'Which is parallel to the <span class="blue">blue</span> line?'
  zh:
    translation:  # these are all zh-Hant
      tap_the_longer_line_html: '儘量選出最長的線。<br>越快越好。'
      which_is_parallel_html: '哪一條線跟<span class="blue">藍</span>色的平行?'


# abstract base class for line perception tasks
LinePerceptionTask = class

  # aspect ratio for the task
  ASPECT_RATIO: 4 / 3  # match iPad

  # how long a fade should take, in msec
  FADE_DURATION: 400

  # minimum intensity for task
  MIN_INTENSITY: 1

  # max intensity for task (set in subclasses)
  MAX_INTENSITY: null

  # task is done after this many reversals (change in direction of
  # intensity change). Bumping against the floor/ceiling also counts
  # as a reversal
  MAX_REVERSALS: 14

  # get this many correct in a row to turn off the practice mode instructions
  PRACTICE_CAPTION_MAX_STREAK: 2

  # get this many correct in a row to leave practice mode
  PRACTICE_MAX_STREAK: 4

  # start practice mode here (set in subclasses)
  PRACTICE_START_INTENSITY: null

  # start intensity of the real task here
  START_INTENSITY: null

  # decrease intensity by this much when correct
  STEPS_DOWN: 1

  # increase intensity by this much when incorrect
  STEPS_UP: 3

  constructor: ->
    @practiceStreakLength = 0

    @staircase = new TabCAT.Task.Staircase(
      intensity: @PRACTICE_START_INTENSITY
      minIntensity: @MIN_INTENSITY
      maxIntensity: @MAX_INTENSITY
      stepsDown: @STEPS_DOWN
      stepsUp: @STEPS_UP
    )

  # call this to show the task onscreen
  start: ->
    TabCAT.Task.start(trackViewport: true)
    TabCAT.UI.turnOffBounce()

    $.i18n.init(resStore: translations, fallbackLng: 'en', useCookie: false)

    $(=>
      TabCAT.UI.requireLandscapeMode($('#task'))
      $('#task').on('mousedown touchstart', @handleStrayTouchStart)
      @showNextTrial()
    )

  # show the next trial for the task
  showNextTrial: ->
    $nextTrialDiv = @getNextTrialDiv()
    $('#task').empty()
    $('#task').append($nextTrialDiv)
    TabCAT.UI.fixAspectRatio($nextTrialDiv, @ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($nextTrialDiv)
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

    TabCAT.Task.logEvent(state, event, interpretation)

    if @staircase.numReversals >= @MAX_REVERSALS
      TabCAT.Task.finish()
    else
      @showNextTrial()

    return

  # event handler for taps that miss the lines
  handleStrayTouchStart: (event) =>
    event.preventDefault()
    TabCAT.Task.logEvent(@getTaskState(), event)
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
      stimuli.practiceCaption = TabCAT.Task.getElementBounds(
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

  # max % difference between line lengths
  MAX_INTENSITY: 50

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
        TabCAT.Task.getElementBounds(div) for div in $('div.line:visible'))
    )


# LINE ORIENTATION

@LineOrientationTask = class extends LinePerceptionTask

  # max angle difference between lines
  MAX_INTENSITY: 89

  # max rotation of the reference line
  MAX_ROTATION: 60

  # minimum difference in orientation between trials
  MIN_ORIENTATION_DIFFERENCE: 20

  # min orientation in practice mode (to avoid the caption)
  MIN_PRACTICE_MODE_ORIENTATION: 25

  # start practice mode here
  PRACTICE_START_INTENSITY: 45

  # range on line length, as a % of container width
  SHORT_LINE_RANGE: [40, 50]

  # start real task here
  START_INTENSITY: 15

  # set up currentStimuli and lastOrientation
  constructor: ->
    super()
    @currentStimuli = {}
    @lastOrientation = 0

  # create the next trial, and return the div containing it, but don't
  # show it or add it to the page (showNextTrial() does this)
  getNextTrialDiv: ->
    # get line offsets and widths for next trial
    trial = @getNextTrial()

    # construct divs for these lines
    $referenceLineDiv = $('<div></div>', class: 'referenceLine')

    $line1Div = $('<div></div>', class: 'line1')
    $line1Div.css(@rotationCss(trial.line1.skew))
    $line1TargetAreaDiv = $('<div></div>', class: 'line1Target')
    $line1TargetAreaDiv.css(@rotationCss(trial.line1.skew))
    $line1TargetAreaDiv.on(
      'mousedown touchstart', trial.line1, @handleLineTouchStart)

    $line2Div = $('<div></div>', class: 'line2')
    $line2Div.css(@rotationCss(trial.line2.skew))
    $line2TargetAreaDiv = $('<div></div>', class: 'line2Target')
    $line2TargetAreaDiv.css(@rotationCss(trial.line2.skew))
    $line2TargetAreaDiv.on(
      'mousedown touchstart', trial.line2, @handleLineTouchStart)

    # put them in a container, and rotate it
    $stimuliDiv = $('<div></div>', class: 'lineOrientationStimuli')
    $stimuliDiv.css(@rotationCss(trial.referenceLine.orientation))
    $stimuliDiv.append(
      $referenceLineDiv,
      $line1Div, $line1TargetAreaDiv,
      $line2Div, $line2TargetAreaDiv)

    # put them in an offscreen div
    $trialDiv = $('<div></div>')
    $trialDiv.hide()

    # show practice caption, if required
    if @shouldShowPracticeCaption()
      $practiceCaptionDiv = $('<div></div>', class: 'practiceCaption')
      $practiceCaptionDiv.html($.t('which_is_parallel_html'))
      $trialDiv.append($practiceCaptionDiv)

    $trialDiv.append($stimuliDiv)

    return $trialDiv

  # generate data, including CSS, for the next trial
  getNextTrial: ->
    orientation = @getNextOrientation()

    # pick direction randomly
    skew = @staircase.intensity * _.sample([-1, 1])

    [line1Skew, line2Skew] = _.shuffle([skew, 0])

    # return this and store in currentStimuli (it's hard to query the browser
    # about rotations)
    @currentStimuli =
      referenceLine:
        orientation: orientation
      line1:
        correct: line1Skew is 0
        skew: line1Skew
      line2:
        correct: line2Skew is 0
        skew: line2Skew

  # pick a new orientation that's not too close to the last one
  getNextOrientation: ->
    while true
      orientation = TabCAT.Math.randomUniform(-@MAX_ROTATION, @MAX_ROTATION)
      if Math.abs(orientation - @lastOrientation) < @MIN_ORIENTATION_DIFFERENCE
        continue

      if @shouldShowPracticeCaption() and (
        Math.abs(orientation) < @MIN_PRACTICE_MODE_ORIENTATION)
        continue

      @lastOrientation = orientation
      return orientation

  rotationCss: (angle) ->
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

  # now, with line orientation information!
  getStimuli: ->
    stimuli = _.extend(super(), @currentStimuli)

    for key in ['line1', 'line2']
      if stimuli[key]?
        stimuli[key] = _.omit(stimuli[key], 'correct')

    return stimuli


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
      $practiceCaptionDiv.html($.t('tap_the_longer_line_html'))
      $containerDiv.append($practiceCaptionDiv)

    return $containerDiv

  # generate data, including CSS, for the next trial
  getNextTrial: ->
    shortLineLength = TabCAT.Math.randomUniform(@SHORT_LINE_RANGE...)

    longLineLength = shortLineLength * (1 + @staircase.intensity / 100)

    [topLineLength, bottomLineLength] = _.shuffle(
      [shortLineLength, longLineLength])

    centerOffset = shortLineLength * @LINE_OFFSET_AT_CENTER / 100

    # make sure both lines are the same distance from the edge of the screen
    totalWidth = topLineLength / 2 + bottomLineLength / 2 + centerOffset
    margin = (100 - totalWidth) / 2

    # push one line to the right, and one to the left
    if _.sample([true, false])
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


# PERPENDICULAR LINE LENGTH

@PerpendicularLineLengthTask = class extends LineLengthTask

  # fit in a square, so all orientations work the same
  ASPECT_RATIO: 1 / 1

  # height of practice caption, as a % of container height, so
  # lines can avoid it
  CAPTION_HEIGHT: 30

  # create the next trial, and return the div containing it, but don't
  # show it or add it to the page (showNextTrial() does this)
  getNextTrialDiv: ->
    # get line offsets and widths for next trial
    trial = @getNextTrial()

    # construct divs for these lines
    $line1Div = $('<div></div>', class: 'line')
    $line1Div.css(trial.line1.css)
    $line1TargetDiv = $('<div></div>', class: 'lineTarget')
    $line1TargetDiv.css(trial.line1.targetCss)
    $line1TargetDiv.on(
      'mousedown touchstart', trial.line1, @handleLineTouchStart)

    $line2Div = $('<div></div>', class: 'line')
    $line2Div.css(trial.line2.css)
    $line2TargetDiv = $('<div></div>', class: 'lineTarget')
    $line2TargetDiv.css(trial.line2.targetCss)
    $line2TargetDiv.on(
      'mousedown touchstart', trial.line2, @handleLineTouchStart)

    # put them in an offscreen div
    $containerDiv = $('<div></div>')
    $containerDiv.hide()
    $containerDiv.append(
      $line1Div, $line1TargetDiv, $line2Div, $line2TargetDiv)

    # show practice caption, if required
    if @shouldShowPracticeCaption()
      $practiceCaptionDiv = $('<div></div>', class: 'practiceCaption')
      $practiceCaptionDiv.html($.t('tap_the_longer_line_html'))
      $containerDiv.append($practiceCaptionDiv)

    return $containerDiv

  # generate data, including CSS, for the next trial
  getNextTrial: ->
    shortLineLength = TabCAT.Math.randomUniform(@SHORT_LINE_RANGE...)

    longLineLength = shortLineLength * (1 + @staircase.intensity / 100)

    # Going to make a sort of T-shaped layout, and rotate it later.
    # The top of the T is the "arm" and the vertical part is the "stem"

    # Alternate between sideways and upright, but pick orientation
    # randomly within that.
    angle = 90 * (@staircase.trialNum % 2)
    angle += _.sample([0, 180])

    if @shouldShowPracticeCaption()
      # when showing the practice caption, always make the vertical
      # line short
      armIsShort = (TabCAT.Math.mod(angle, 180) == 90)
    else
      armIsShort = _.sample([true, false])

    if armIsShort
      [armLength, stemLength] = [shortLineLength, longLineLength]
    else
      [armLength, stemLength] = [longLineLength, shortLineLength]

    totalHeight = stemLength + @LINE_WIDTH * 2
    verticalMargin = (100 - totalHeight) / 2

    arm =
      top: verticalMargin
      bottom: verticalMargin + @LINE_WIDTH
      height: @LINE_WIDTH
      left: (100 - armLength) / 2
      right: (100 + armLength) / 2
      width: armLength

    stem =
      top: verticalMargin + 2 * @LINE_WIDTH
      bottom: 100 - verticalMargin
      height: stemLength
      width: @LINE_WIDTH

    # offset stem to the left or right to avoid perseverative tapping
    # in the center of the screen
    if _.sample([true, false])
      stem.left = arm.left + @LINE_WIDTH
    else
      stem.left = arm.right - @LINE_WIDTH * 2
    stem.right = stem.left + @LINE_WIDTH

    # rotate the "T" shape
    line1Box = @rotatePercentBox(arm, angle)
    line2Box = @rotatePercentBox(stem, angle)

    # if we want to show a practice caption, shift the whole thing down
    if @shouldShowPracticeCaption()
      offset = @CAPTION_HEIGHT - Math.min(line1Box.top, line2Box.top)
      line1Box.top += offset
      line1Box.bottom += offset
      line2Box.top += offset
      line2Box.bottom += offset

    line1TargetBox = @makeTargetBox(line1Box)
    line2TargetBox = @makeTargetBox(line2Box)

    line1Css = @percentBoxToCss(line1Box)
    line1TargetCss = @percentBoxToCss(line1TargetBox)
    line2Css = @percentBoxToCss(line2Box)
    line2TargetCss = @percentBoxToCss(line2TargetBox)

    return {
      line1:
        correct: (armLength >= stemLength)
        css: line1Css
        targetCss: line1TargetCss
      line2:
        correct: (stemLength >= armLength)
        css: line2Css
        targetCss: line2TargetCss
      angle: angle
    }

  rotatePercentBox: (box, angle) ->
    if (angle % 90 != 0)
      throw Error("angle must be a multiple of 90")

    angle = TabCAT.Math.mod(angle, 360)
    if (angle == 0)
      return box

    return @rotatePercentBox({
      top: 100 - box.right
      bottom: 100 - box.left
      height: box.width
      left: box.top
      right: box.bottom
      width: box.height
    }, angle - 90)

  percentBoxToCss: (box) ->
    css = {}
    for own key, value of box
      css[key] = value + '%'

    return css

  makeTargetBox: (box, borderWidth) ->
    borderWidth ?= @TARGET_BORDER

    return {
      top: box.top - borderWidth
      bottom: box.top + borderWidth
      height: box.height + borderWidth * 2
      left: box.left - borderWidth
      right: box.right + borderWidth
      width: box.width + borderWidth * 2
    }
