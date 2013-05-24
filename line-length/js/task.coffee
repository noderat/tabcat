LL = {}

LL.debugMode = false

LL.startTimestamp = null
LL.endTimestamp = null

fontSizeAsPercentOfHeight = 2
aspectRatio = 4/3  # pretend we're on an iPad

# as a percentage of container
shortLineMinLength = 40
shortLineMaxLength = 50
# as a percentage of the short line's length
lineOffsetAtCenter = 50

minIntensity = 1
maxIntensity = 50
intensityChangeOnHit = -1
intensityChangeOnMiss = 3
startIntensity = 15
practiceStartIntensity = 40
LL.intensity = practiceStartIntensity
# used to track reversals. not maintained in practice mode
LL.lastIntensityChange = 0

maxReversals = 20
LL.intensitiesAtReversal = []
LL.numTrials = 0

practiceMaxStreakLength = 4
practiceCaptionMaxStreakLength = 2
LL.practiceStreakLength = 0

numLayouts = 2

inPracticeMode = -> LL.practiceStreakLength < practiceMaxStreakLength

shouldShowPracticeCaption = ->
  LL.practiceStreakLength < practiceCaptionMaxStreakLength

taskIsDone = -> LL.intensitiesAtReversal.length >= maxReversals

randomUniform = (a, b) -> a + Math.random() * (b - a)

coinFlip = -> Math.random() < 0.5

clamp = (min, x, max) -> Math.min(max, Math.max(min, x))


recordResult = (correct) ->
  if LL.startTimestamp is null
    LL.startTimestamp = $.now()

  change = if correct then intensityChangeOnHit else intensityChangeOnMiss

  lastIntensity = LL.intensity
  LL.intensity = clamp(minIntensity, lastIntensity + change, maxIntensity)
  intensityChange = LL.intensity - lastIntensity

  if inPracticeMode()
    if correct
      LL.practiceStreakLength += 1
      if not inPracticeMode()  # i.e. we just left practice mode
        LL.intensity = startIntensity
        LL.lastIntensityChange = 0
    else
      LL.practiceStreakLength = 0
  else
    wasReversal = (intensityChange * LL.lastIntensityChange < 0 or
                   intensityChange is 0)
    if wasReversal
      LL.intensitiesAtReversal.push(lastIntensity)
    LL.lastIntensityChange = intensityChange

  LL.numTrials += 1


LL.getNextTrial = ->
  shortLineLength = randomUniform(shortLineMinLength, shortLineMaxLength)

  longLineLength = shortLineLength * (1 + LL.intensity / 100)

  if coinFlip()
    [topLineLength, bottomLineLength] = [shortLineLength, longLineLength]
  else
    [bottomLineLength, topLineLength] = [shortLineLength, longLineLength]

  centerOffset = shortLineLength * lineOffsetAtCenter / 100

  # make sure both lines are the same distance from the edge of the screen
  totalWidth = topLineLength / 2 + bottomLineLength / 2 + centerOffset
  margin = (100 - totalWidth) / 2

  # push one line to the right, and one to the left
  if coinFlip()
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
    intensity: LL.intensity
  }


LL.showNextTrial = (event) ->
  if event and event.data
    recordResult(event.data.isLonger)

  if taskIsDone()
    LL.finishTask()
  else
    nextTrialDiv = LL.nextTrialDiv()
    $('#task-main').empty()
    $('#task-main').append(nextTrialDiv)
    TabCAT.UI.fixAspectRatio(nextTrialDiv, aspectRatio)
    TabCAT.UI.fixFontSize(nextTrialDiv)
    $(nextTrialDiv).fadeIn({duration: 200})


LL.finishTask = (event) ->
  LL.endTimestamp = $.now()

  $('#scoring .score-list').text(LL.intensitiesAtReversal.join(', '))
  elapsedSecs = (LL.endTimestamp - LL.startTimestamp) / 1000
  # we start timing after the first click, so leave out the first
  # trial in timing info
  $('#scoring .elapsed-time').text(
    elapsedSecs.toFixed(1) + 's / ' + (LL.numTrials - 1) + ' = ' +
    (elapsedSecs / (LL.numTrials - 1)).toFixed(1) + 's')

  $('#task').hide()
  $('#done').fadeIn({duration: 200})

  $('#show-scoring').bind('click', LL.showScoring)
  $('#show-scoring').removeAttr('disabled')


LL.showScoring = (event) ->
  $('#done').hide()
  $('#scoring').fadeIn({duration: 200})


LL.nextTrialDiv = ->
  # get line offsets and widths for next trial
  trial = LL.getNextTrial()

  # construct divs for these lines
  topLineDiv = $('<div></div>', {'class': 'line top-line'})
  topLineDiv.css(trial.topLine.css)
  topLineDiv.bind('click', trial.topLine, LL.showNextTrial)

  bottomLineDiv = $('<div></div>', {'class': 'line bottom-line'})
  bottomLineDiv.css(trial.bottomLine.css)
  bottomLineDiv.bind('click', trial.bottomLine, LL.showNextTrial)

  if (LL.debugMode)
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
    'class': 'layout-' + LL.numTrials % numLayouts})
  $(containerDiv).hide()
  containerDiv.append(topLineDiv, bottomLineDiv)

  # show practice caption, if required
  if shouldShowPracticeCaption()
    practiceCaptionDiv = $('<div></div>',
      {'class': 'practice-caption'})
    practiceCaptionDiv.html('Tap the longer line<br>' +
      ' quickly and accurately.')
    containerDiv.append(practiceCaptionDiv)

  return containerDiv


# add to the global object
this.LL = LL


# initialize the page

# turn off scrolling/bounce
$(document).bind('touchmove', (event) ->
  event.preventDefault())

TabCAT.UI.fixFontSize($(document.body), fontSizeAsPercentOfHeight)

# enable fast click
$(-> FastClick.attach(document.body))

LL.showNextTrial()
