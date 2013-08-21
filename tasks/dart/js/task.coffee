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

# how long after loading to show the "video is stalled" message
VIDEO_LOAD_WAIT_TIME = 3000

# how long to wait before showing the "video is stalled" message
# (because the video might un-stall on its own)
VIDEO_STALLED_WAIT_TIME = 1000



# GLOBALS

trialNum = 0

# used to help restart the video if it stalls due to flaky network
restartVideoAt = null

# used to track whether the video is still stalled
videoIsStalled = false


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
  video = $video[0]

  $video.on('play', (event) ->
    tabcat.task.logEvent(getState(), event)
    tabcat.ui.wait(VIDEO_OVERLAY_SHOW_TIME).then(->
      $('#videoLabel').fadeOut(duration: VIDEO_OVERLAY_FADE_OUT_TIME)
    )
  )

  $video.on('ended', (event) ->
    tabcat.task.logEvent(getState(), event)
    showChoices()
  )

  fixVideoCurrentTime = ->
    # seeking on the iPad is a pain; see goo.gl/vvy8oq for details
    if (
      restartVideoAt? and video.seekable?.length and \
      video.seekable.start(0) <= restartVideoAt <= video.seekable.end(0))

      video.currentTime = restartVideoAt
      restartVideoAt = null

  # video elements can't receive click events on iPad Safari, so attach them
  # to a transparent overlay instead.
  $('#videoResume').on('click', (event) ->
    tabcat.task.logEvent(getState(), event)

    # store this for when the video is ready to be fast-forwarded
    # see .on('loadedmetadata', ...) below
    restartVideoAt = video.currentTime ? 0
    # if we stalled at the end of the video, just show choices
    $('#videoStalled').hide()
    loadAndPlayVideo()
  )

  $video.on('abort error stalled', (event) ->
    tabcat.task.logEvent(getState(), event)

    videoIsStalled = true

    tabcat.ui.wait(VIDEO_STALLED_WAIT_TIME).then(->
      if videoIsStalled
        $('#videoLabel').hide()
        $('#videoStalled').show()
    )
  )

  $video.on('timeupdate', ->
    videoIsStalled = false
    $('#videoStalled').hide()
    fixVideoCurrentTime()
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

  $videoScreen = $('#videoScreen')
  if $videoScreen.is(':visible')
    video = $videoScreen.find('video')[0]
    stimuli.video = {}
    stimuli.video.currentTime = video.currentTime
    if $('#videoStalled').is(':visible')
      stimuli.video.stalled = true
    stimuli.video.duration = video.duration
    stimuli.video.readyState = video.readyState
    stimuli.video.networkState = video.networkState
    # not including video number, because it's the same as trialNum

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
  # if video stalls near the end, things can get messy; don't
  # show choices twice
  if $('choicesScreen').is(':visible')
    return

  $('#videoScreen').hide()
  $('#choiceSubmitButton').hide()

  # randomly populate choices
  choices = _.shuffle(CHOICES)
  for choice, i in choices
    $('#choice-' + i).text(choice)

  # don't choose any of them
  $choices = $('#choices').find('div')
  $choices.removeClass('chosen')

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

  $videoScreen = $('#videoScreen')

  $videoLabel = $('#videoLabel')
  $videoLabel.text(videoLabel())
  $videoLabel.show()

  # we're playing a new video, so clear out old restart time, if any
  restartVideoAt = null
  loadAndPlayVideo()

  $videoScreen.show()


# load and play video, in the tiresome way that Safari requires
loadAndPlayVideo = ->
  $video = $('#videoScreen').find('video')

  video = $video[0]

  # clear video.src, in case we are trying to reload the same video
  video.src = null

  if video.canPlayType('video/ogg')
    video.src = "videos/#{trialNum}.ogv"
  else
    video.src = "videos/#{trialNum}.mp4"

  # manually set the size of the video, for Safari
  #
  # don't use $video.attr('width', ...); it just confuses jQuery/iOS Safari
  squareDivHeight = $('div.square').height()
  $video.width(squareDivHeight)
  $video.height(squareDivHeight)

  video.load()

  # would be better to do this on canplay, but iOS Safari only allows
  # videos to be played from user-triggered events
  video.play()


inPracticeMode = -> trialNum is 0

videoLabel = ->
  if inPracticeMode() then 'Practice Item' else trialNum
