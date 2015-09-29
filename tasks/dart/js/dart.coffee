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

# how long to the video can stall before we show user a message
VIDEO_MAX_STALL_TIME = 3000



# GLOBALS

trialNum = 0

# used to help restart the video if it stalls due to flaky network
restartVideoAt = null

# used to show the "video is stalled" message
videoStalledTimeoutId = null


# INITIALIZATION

@initTask = ->
  TabCAT.Task.start(trackViewport: true)

  TabCAT.UI.enableFastClick()
  TabCAT.UI.turnOffBounce()

  $(onReady)


onReady = ->
  initVideoScreen()
  initChoiceScreen()
  showInstructions()


# INSTRUCTIONS

showInstructions = ->
  $squareDiv = $('div.square')
  TabCAT.UI.fixAspectRatio($squareDiv, 1)
  TabCAT.UI.linkEmToPercentOfHeight($squareDiv)

  $('#instructionsScreen').find('button').on('click', showVideo)

  $('#instructionsScreen').show()


# VIDEO

# set up all the events for the video screen
initVideoScreen = _.once(->
  $video = $('#videoScreen').find('video')
  video = $video[0]

  # when the video starts playing, hide the label overlay
  $video.on('play', (event) ->
    TabCAT.Task.logEvent(getState(), event)
    TabCAT.UI.wait(VIDEO_OVERLAY_SHOW_TIME).then(->
      $('#videoLabel').fadeOut(duration: VIDEO_OVERLAY_FADE_OUT_TIME)
    )
  )

  # if the video ended, show choices
  $video.on('ended', (event) ->
    TabCAT.Task.logEvent(getState(), event)
    clearStalledMessage()
    showChoices()
  )

  # video elements can't receive click events on iPad Safari, so attach them
  # to a transparent overlay instead.
  $('#videoResume').on('mousedown touchstart', (event) ->
    event.preventDefault()  # stop mousedown emulation
    TabCAT.Task.logEvent(getState(), event)

    if $('#videoStalled').is(':visible')
      # store this for when the video is ready to be fast-forwarded
      # if a previous click event already tried to reload the video, don't
      # lose the old restartVideoAt time
      restartVideoAt = Math.max(restartVideoAt, video.currentTime, 0)
      # if we stalled at the end of the video, just show choices
      $('#videoStalled').hide()
      loadAndPlayVideo()
      deferStalledMessage()
  )

  # handle resume if we can, and defer showing the "video stalled" message
  $video.on('loadedmetadata progress timeupdate', ->
    deferStalledMessage()
    fixVideoCurrentTime()
  )

  # implements resume
  fixVideoCurrentTime = ->
    # seeking on the iPad is a pain; see goo.gl/vvy8oq for details
    if (
      restartVideoAt? and video.seekable?.length and \
      video.seekable.start(0) <= restartVideoAt <= video.seekable.end(0))

        video.currentTime = restartVideoAt
      restartVideoAt = null

  # log problems loading the video, but don't do anything about them
  $video.on('abort error stalled', (event) ->
    TabCAT.Task.logEvent(getState(), event)
  )

)

# show the video screen and start playing the video
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
  deferStalledMessage()

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

# how to label
videoLabel = ->
  if inPracticeMode() then 'Practice Item' else trialNum

# show the "video stalled" message after a certain amount of time (unless
# this function or clearStalledMessage() gets called before then)
deferStalledMessage = (milliseconds) ->
  milliseconds ?= VIDEO_MAX_STALL_TIME
  clearStalledMessage()
  videoStalledTimeoutId = window.setTimeout(showStalledMessage, milliseconds)

# hide the "video stalled" message
clearStalledMessage = ->
  if videoStalledTimeoutId?
    window.clearTimeout(videoStalledTimeoutId)
  videoStalledTimeoutId = null
  if $('#videoStalled').is(':visible')
    $('#videoStalled').hide()
    # log that we hid the message
    TabCAT.Task.logEvent(getState())

# show the "video stalled" message (helper for call deferStalledMessage())
showStalledMessage = ->
  $('#videoLabel').hide()
  $('#videoStalled').fadeIn(duration: FADE_DURATION)
  # log that we showed the message
  TabCAT.Task.logEvent(getState())


# CHOICES

initChoiceScreen = _.once(->
  $choices = $('#choices')

  for __, i in CHOICES
    $choice = $('<div></div>', class: 'choice', id: 'choice-' + i)
    $choices.append($choice)
    $choice.on('mousedown touchstart', i, onPickChoice)

  $('#choiceSubmitButton').on('click', onSubmitChoice)
)


# get the choice already selected on the screen
getChosen = ->
  return $('#choices:visible').find('div.chosen').text() or null



onPickChoice = (event) ->
  event.preventDefault()  # stop mouseDown emulation

  $target = $(event.target)
  $choices = $('#choices').find('div')

  choice = $target.text()
  TabCAT.Task.logEvent(getState(), event, interpretChoice(choice))

  # make choices act like radio buttons
  if not $target.hasClass('chosen')
    $choices.removeClass('chosen')
    $target.addClass('chosen')

  # show button if it's not already shown
  $submitButton = $('#choiceSubmitButton')
  if $submitButton.length
    TabCAT.UI.wait(CHOICES_SUBMIT_SHOW_WAIT).then(->
      $submitButton.fadeIn(duration: FADE_DURATION)
    )


onSubmitChoice = (event) ->
  TabCAT.Task.logEvent(getState(), event, interpretSubmission())

  trialNum += 1

  if trialNum >= NUM_VIDEOS
    TabCAT.Task.finish(interpretation: finalInterpretation())
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

  $('#choicesVideoLabel').text(videoLabel())

  $('body').addClass('blueBackground')
  $('#choicesScreen').fadeIn(duration: FADE_DURATION)




# STATE AND INTERPRETATION

getState = ->
  state =
    trialNum: trialNum

  if inPracticeMode()
    state.practiceMode = true

  stimuli = getStimuli()
  if not _.isEmpty(stimuli)
    state.stimuli = stimuli

  return state

getStimuli = ->
  stimuli = {}

  $videoScreen = $('#videoScreen')
  if $videoScreen.is(':visible')
    video = $videoScreen.find('video')[0]
    stimuli.video = {}
    stimuli.video.currentTime = video.currentTime
    if $('#videoStalled').is(':visible')
      stimuli.video.stalled = true
    # not including video number, because it's the same as trialNum

  $choiceDivs = $('#choices:visible').find('div')
  if $choiceDivs.length
    stimuli.choices = ($(c).text() for c in $choiceDivs)

  chosen = getChosen()
  if chosen
    stimuli.chosen = chosen

  return stimuli


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
    (item for item in TabCAT.Task.getEventLog() when (
      not item.state?.practiceMode and
      item.interpretation?.submit and
      item.interpretation?.correct)).length


inPracticeMode = -> trialNum is 0
