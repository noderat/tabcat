# VIDEOS
NUM_VIDEOS = 13



videoNum = 0

inPracticeMode = -> videoNum is 0


videoLabel = ->
  if inPracticeMode() then 'Practice Item' else videoNum


# INITIALIZATION
@taskInit = ->
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

  $('.videoLabel').text(videoLabel())

  $('#mp4Source').attr('src', "videos/#{videoNum}.mp4")
  $('#oggSource').attr('src', "videos/#{videoNum}.ogv")

  $videoContainer = $('#videoContainer')
  video = $videoContainer.find('video')[0]

  video.load()
  $videoContainer.show()
