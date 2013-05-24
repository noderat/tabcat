debugMode = false

startTimestamp = null
endTimestamp = null

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
intensity = practiceStartIntensity
# used to track reversals. not maintained in practice mode
lastIntensityChange = 0

maxReversals = 20
intensitiesAtReversal = []
numTrials = 0

practiceMaxStreakLength = 4
practiceCaptionMaxStreakLength = 2
practiceStreakLength = 0

numLayouts = 2

inPracticeMode = -> practiceStreakLength < practiceMaxStreakLength

shouldShowPracticeCaption = ->
  practiceStreakLength < practiceCaptionMaxStreakLength

taskIsDone = -> intensitiesAtReversal.length >= maxReversals

randomUniform = (a, b) -> a + Math.random() * (b - a)

coinFlip = -> Math.random() < 0.5

clamp = (min, x, max) -> Math.min(max, Math.max(min, x))


recordResult = (correct) ->
  if startTimestamp is null
    startTimestamp = $.now()

  change = if correct then intensityChangeOnHit else intensityChangeOnMiss

  lastIntensity = intensity
  intensity = clamp(minIntensity, lastIntensity + change, maxIntensity)
  intensityChange = intensity - lastIntensity

  if inPracticeMode()
    if correct
      practiceStreakLength += 1
      if not inPracticeMode()  # i.e. we just left practice mode
        intensity = startIntensity
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


getNextTrial = ->
  shortLineLength = randomUniform(shortLineMinLength, shortLineMaxLength)

  longLineLength = shortLineLength * (1 + intensity / 100)

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
    intensity: intensity
  }


showNextTrial = (event) ->
  if event and event.data
    recordResult(event.data.isLonger)

  if taskIsDone()
    finishTask()
  else
    nextTrialDiv = getNextTrialDiv()
    $('#task-main').empty()
    $('#task-main').append(nextTrialDiv)
    tabcat.ui.fixAspectRatio(nextTrialDiv, aspectRatio)
    tabcat.ui.fixFontSize(nextTrialDiv)
    $(nextTrialDiv).fadeIn({duration: 200})


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
  $('#done').fadeIn({duration: 200})

  $('#show-scoring').bind('click', showScoring)
  $('#show-scoring').removeAttr('disabled')


showScoring = (event) ->
  $('#done').hide()
  $('#scoring').fadeIn({duration: 200})


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

  if (debugMode)
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
    'class': 'layout-' + numTrials % numLayouts})
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

# initialize the page

# turn off scrolling/bounce
$(document).bind('touchmove', (event) ->
  event.preventDefault())

tabcat.ui.fixFontSize($(document.body), fontSizeAsPercentOfHeight)

# enable fast click
$(-> FastClick.attach(document.body))

showNextTrial()
