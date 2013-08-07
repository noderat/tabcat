# Content

CHOICES = ['afraid', 'angry', 'disgusted', 'happy', 'sad', 'surprised']

NUM_CHOICES = CHOICES.length

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
  tabcat.task.start()

  tabcat.ui.enableFastClick()
  tabcat.ui.turnOffBounce()

  $(onReady)


onReady = ->
  initVideo()
  initChoices()
  showInstructions()


initVideo = _.once(->
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

  # TODO: remove this
  $video.on('click', (event) ->
    event.target.pause()
    showChoices()
  )

  $video.on('canplay', (event) ->
    event.target.play()
  )
)


initChoices = _.once(->
  $choicesDiv = $('#choicesDiv')

  for i in [0..NUM_CHOICES-1]
    $label = $('<label></label>')
    $input = $('<input>', type: 'radio', name: 'emotion', id: 'choice-' + i)
    $span = $('<span></span>', id: 'choice-span-' + i)
    $label.append($input, $span, $('<br>'))
    $choicesDiv.append($label)

    $label.on('click', i, onPickChoice)

  $('#choicesForm').on('submit', onChoiceSubmit)
)


getChoice = ->
  return _.object($('#choicesForm').serializeArray())['emotion']


getState = ->
  state =
    trialNum: trialNum

  $radioButtons = $('#choicesForm:visible').find('input[type=radio]')
  if $radioButtons.length
    state.choices = [$(rb).attr('value') for rb in $radioButtons]

  if inPracticeMode()
    state.practiceMode = true

  return state


interpretChoice = ->
  choice = getChoice()
  correctChoice = CORRECT_CHOICES[trialNum]

  interpretation =
    choice: choice
    correct: choice is correctChoice

  if not interpretation.correct
    interpretation.correctChoice = correctChoice

  return interpretation


onPickChoice = (event) ->
  $submitButton = $('#choicesSubmitButton')
  if $submitButton.length
    tabcat.ui.wait(CHOICES_SUBMIT_SHOW_WAIT).then(->
      $submitButton.fadeIn(duration: FADE_DURATION)
    )

  tabcat.task.logEvent(getState(), event, interpretChoice())


onChoiceSubmit = (event) ->
  event.preventDefault()

  tabcat.task.logEvent(getState(), event, interpretChoice())

  trialNum += 1

  if trialNum >= NUM_VIDEOS
    # TODO: final interpretation
    tabcat.task.finish()
  else
    showVideo()


showChoices = ->
  $('#videoScreen').hide()
  $('#choicesSubmitButton').hide()

  # randomly populate choices
  choices = _.shuffle(CHOICES)
  for choice, i in choices
    $('#choice-' + i).attr('value', choice)
    $('#choice-span-' + i).text(choice)

  $('#videoLabel').text(videoLabel())

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
  $videoOverlay.text(videoLabel())
  $videoOverlay.show()

  $('#mp4Source').attr('src', "videos/#{trialNum}.mp4")
  $('#oggSource').attr('src', "videos/#{trialNum}.ogv")

  video = $videoContainer.find('video')[0]

  video.load()
  $videoContainer.show()


inPracticeMode = -> trialNum is 0

videoLabel = ->
  if inPracticeMode() then 'Practice Item' else trialNum
