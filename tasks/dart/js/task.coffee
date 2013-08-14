# Content

# Note: CSS layout currently only supports up to 6 choices
CHOICES = ['afraid', 'angry', 'disgusted', 'happy', 'sad', 'surprised']

CORRECT_CHOICES = [
  'happy',
  'angry',
  'happy',
  'surprised',
  'afraid',
  'disgusted',
  'sad',
  'afraid',
  'angry',
  'disgusted',
  'happy',
  'sad',
  'surprised',
]

NUM_VIDEOS = CORRECT_CHOICES.length

# Look and Feel

VIDEO_OVERLAY_SHOW_TIME = 1000
VIDEO_OVERLAY_FADE_OUT_TIME = 1500

CHOICES_SUBMIT_SHOW_WAIT = 1000

FADE_DURATION = 200


# GLOBALS

trialNum = 0




# INITIALIZATION
@initTask = ->
  tabcat.task.start(trackViewport: true)

  tabcat.ui.enableFastClick()
  tabcat.ui.turnOffBounce()

  $(onReady)


onReady = ->
  initVideoScreen()
  initChoiceScreen()
  showInstructions()


initVideoScreen = _.once(->
  $video = $('#videoScreen').find('video')

  $video.on('play', (event) ->
    tabcat.task.logEvent(getState(), event)
    tabcat.ui.wait(VIDEO_OVERLAY_SHOW_TIME).then(->
      $('#videoOverlay').fadeOut(duration: VIDEO_OVERLAY_FADE_OUT_TIME)
    )
  )

  $video.on('ended', (event) ->
    tabcat.task.logEvent(getState(), event)
    showChoices()
  )
)


initChoiceScreen = _.once(->
  $choices = $('#choices')

  for __, i in CHOICES
    $choice = $('<div></div>', class: 'choice', id: 'choice-' + i)
    $choices.append($choice)
    $choice.on('click', i, onPickChoice)

  $('#choiceSubmitButton').on('click', onSubmitChoice)
)


# get the choice already selected on the screen
getChosen = ->
  return $('#choices:visible').find('div.chosen').text() or null


getStimuli = ->
  stimuli = {}

  if $('#videoScreen:visible').length
    stimuli.video = true

  $choiceDivs = $('#choices:visible').find('div')
  if $choiceDivs.length
    stimuli.choices = ($(c).text() for c in $choiceDivs)

  chosen = getChosen()
  if chosen
    stimuli.chosen = chosen

  return stimuli


getState = ->
  state =
    trialNum: trialNum

  if inPracticeMode()
    state.practiceMode = true

  stimuli = getStimuli()
  if not _.isEmpty(stimuli)
    state.stimuli = stimuli

  return state


interpretChoice = (choice) ->
  correctChoice = CORRECT_CHOICES[trialNum]

  interpretation =
    choice: choice
    correct: choice is correctChoice

  if not interpretation.correct
    interpretation.correctChoice = correctChoice

  return interpretation


interpretSubmission = ->
  $.extend(interpretChoice(getChosen()), submit: true)


finalInterpretation = ->
  numCorrect:
    (item for item in tabcat.task.getEventLog() when (
      not item.state?.practiceMode and
      item.interpretation?.submit and
      item.interpretation?.correct)).length


onPickChoice = (event) ->
  $target = $(event.target)
  $choices = $('#choices').find('div')

  choice = $target.text()
  tabcat.task.logEvent(getState(), event, interpretChoice(choice))

  # make choices act like radio buttons
  if not $target.hasClass('chosen')
    $choices.removeClass('chosen')
    $target.addClass('chosen')

  # show button if it's not already shown
  $submitButton = $('#choiceSubmitButton')
  if $submitButton.length
    tabcat.ui.wait(CHOICES_SUBMIT_SHOW_WAIT).then(->
      $submitButton.fadeIn(duration: FADE_DURATION)
    )


onSubmitChoice = (event) ->
  tabcat.task.logEvent(getState(), event, interpretSubmission())

  trialNum += 1

  if trialNum >= NUM_VIDEOS
    tabcat.task.finish(interpretation: finalInterpretation())
  else
    showVideo()


showChoices = ->
  $('#videoScreen').hide()
  $('#choiceSubmitButton').hide()

  # randomly populate choices
  choices = _.shuffle(CHOICES)
  for choice, i in choices
    $('#choice-' + i).text(choice)

  # don't choose any of them
  $choices = $('#choices').find('div')
  $choices.removeClass('chosen')

  $('#trialLabel').text(trialLabel())

  $('body').addClass('blueBackground')
  $('#choicesScreen').fadeIn(duration: FADE_DURATION)


showInstructions = ->
  $squareDiv = $('div.square')
  tabcat.ui.fixAspectRatio($squareDiv, 1)
  tabcat.ui.linkEmToPercentOfHeight($squareDiv)

  $('#instructionsScreen').show()

  $('#instructionsScreen').find('button').on('click', showVideo)


showVideo = ->
  $('#instructionsScreen').hide()
  $('#choicesScreen').hide()
  $('body').removeClass('blueBackground')

  $videoContainer = $('#videoScreen')

  $videoOverlay = $('#videoOverlay')
  $videoOverlay.text(trialLabel())
  $videoOverlay.show()

  $video = $videoContainer.find('video')
  video = $video[0]

  if video.canPlayType('video/ogg')
    video.src = "videos/#{trialNum}.ogv"
  else
    video.src = "videos/#{trialNum}.mp4"

  # manually set the size of the video, for iPad
  #
  # don't use $video.attr('width', ...); it just confuses jQuery/iOS Safari
  squareDivHeight = $('div.square').height()
  $video.width(squareDivHeight)
  $video.height(squareDivHeight)

  video.load()
  video.play()

  # would be better to do this on canplay, but iOS only allows
  # videos to be played from user-triggered events
  $videoContainer.show()


inPracticeMode = -> trialNum is 0

trialLabel = ->
  if inPracticeMode() then 'Practice Item' else trialNum
