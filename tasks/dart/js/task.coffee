# VIDEOS
NUM_VIDEOS = 13

VIDEO_OVERLAY_SHOW_TIME = 1000
VIDEO_OVERLAY_FADE_OUT_TIME = 1500



videoNum = 0

inPracticeMode = -> videoNum is 0


videoLabel = ->
  if inPracticeMode() then 'Practice Item' else videoNum


# INITIALIZATION
@initTask = ->
  tabcat.task.start()

  tabcat.ui.enableFastClick()
  tabcat.ui.turnOffBounce()

  $(onReady)


onReady = ->
  initVideoEvents()
  showInstructions()


initVideoEvents = _.once(->
  $video = $('#videoContainer').find('video')

  $video.on('play', (event) ->
    tabcat.task.logEvent(videoNum: videoNum, event)
    tabcat.ui.wait(VIDEO_OVERLAY_SHOW_TIME).then(->
      $('#videoOverlay').fadeOut(duration: VIDEO_OVERLAY_FADE_OUT_TIME)
    )
  )

  $video.on('ended', (event) ->
    tabcat.task.logEvent(videoNum: videoNum, event)
    showChoices()
  )

  $video.on('canplay', (event) ->
    event.target.play()
  )
)


showInstructions = ->
  $squareDiv = $('div.square')
  tabcat.ui.fixAspectRatio($squareDiv, 1)
  tabcat.ui.linkEmToPercentOfHeight($squareDiv)

  $('#instructions').show()

  $('#instructions').find('button').on('click', showVideo)


showVideo = ->
  $('#instructions').hide()
  $('#choices').hide()
  $('body').removeClass('blueBackground')

  $videoContainer = $('#videoContainer')

  $videoOverlay = $('#videoOverlay')
  $videoOverlay.text(videoLabel())
  $videoOverlay.show()

  $('#mp4Source').attr('src', "videos/#{videoNum}.mp4")
  $('#oggSource').attr('src', "videos/#{videoNum}.ogv")

  video = $videoContainer.find('video')[0]

  video.load()
  $videoContainer.show()
