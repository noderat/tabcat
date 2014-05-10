
# The Set Shifting block runs a set number of trials (randomly ordered)
# and each trial has the following structure:
#   1) Initial Delay: 800 ms (delay at beginning of trial)
#   2) Cue Duration: 800 ms (time condition cue is displayed before fixation)
#   3) Fixation Delay: 200 ms (time to display the fixation cue)
#   4) target image: 5 seconds (or until response)
#   5) Feedback During Practice: 2 seconds

translations =
  en:
    translation:
      begin_html:
        'Begin'
      next_html:
        'Next'
      practice_html:
        1: 'This is a matching task.</br>' +
           'You will see an object in the center of the screen, and a word ' +
           'at the bottom of the screen.  The word will be SHAPE or COLOR.' +
           'The word at the bottom of the screen will tell you how to match' +
           'the object in the center to one of the objects in the corners.'
        2: 'When you have to match by COLOR, you should push the ' +
           'LEFT button for RED and the RIGHT button for BLUE.'
        3: 'When you have to match by SHAPE, you should push the ' +
           'LEFT button for TRIANGLE and the RIGHT button for RECTANGLE.'
      practice2_html:
        1: 'Try to respond quickly and accurately, but if you make ' +
           'a mistake just keep going. We\'ll try some practice trials first.'
        2: 'Tap the "Begin" button to begin.'
      additional_practice_html:
        1: 'You have completed the practice trial. ' +
           'Let\'s do another practice trial. The instrucctions are the same.'
        2: 'When you have to match by COLOR, you should push the ' +
           'left button for red and the right button for blue.'
        3: 'LEFT = RED'
        4: 'RIGHT = BLUE'
        5: 'When you have to match by SHAPE, you should push the left ' +
           'button for triangle and the right button for rectangle. '
        6: 'LEFT = TRIANGLE'
        7: 'RIGHT = RECTANGLE'
        8: 'Tap the "Begin" button to begin.'
      testing_html:
        1: 'Now let\'s move on to the task, the instructions are the same ' +
           'but you will no longer receive feedback after your responses.'
        2: 'When you have to match by COLOR, you should push the LEFT ' +
           'button for RED and the RIGHT button for BLUE.'
        3: 'When you have to match by SHAPE, you should push the LEFT ' +
           'button for TRIANGLE and the RIGHT button for RECTANGLE.'
        4: 'Try to respond quickly and accurately, but if you make ' +
           'a mistake just keep going.'
        5: 'Tap the "Begin" button to begin.'
      color_cue:
        'COLOR'
      feedback_correct:
        'Correct!'
      feedback_incorrect:
        'Incorrect.'
      feedback_no_response:
        'No response detected.'
      shape_cue:
        'SHAPE'


# for debugging
pp = (msg) ->
  $debug = $('#debug')
  if Object.prototype.toString.call(msg) is '[object Array]'
    $debug.append('</br>' + JSON.stringify(val) for val in msg)
  else
    $debug.append(JSON.stringify(msg,null,4)).append('</br>')

# one second delay before each block
BEFORE_BLOCK_DELAY = 1000

# duration of delay at beginning of trial
PRE_TRIAL_DELAY = 800

# condition cue is the word 'color' or 'shape'
# length of time the condition cue is displayed before fixation
CUE_DURATION = 800

# length of time to display the fixation cue
FIXATION_DURATION = 200

# length of time to display the target
TARGET_DURATION = 800

# time the target is displayed from start of trial
TARGET_DISPLAY_TIME = PRE_TRIAL_DELAY + CUE_DURATION + FIXATION_DURATION

# trial times out 5 seconds after target display
TRIAL_TIMEOUT = TARGET_DISPLAY_TIME + 5000

FEEDBACK_DURATION = 2000

# If subjects gets 12/16 trials correct in a practice trial
# then skip ahead to real testing. If subjects fails get this
# number correct in 3 practice blocks then end the task
PRACTICE_MIN_CORRECT = 12

# Max number of practice blocks to try before aborting task
PRACTICE_MAX_BLOCKS = 3

# main div's aspect ratio (pretend we're on an iPad)
ASPECT_RATIO = 4/3

FIXATION = 'x'

# possible responses
RED_TRIANGLE   = {'color': 'red' , 'shape': 'triangle'}
BLUE_RECTANGLE = {'color': 'blue', 'shape': 'rectangle'}

# possible targets
RED_RECTANGLE = {'color': 'red' , 'shape': 'rectangle'}
BLUE_TRIANGLE = {'color': 'blue', 'shape': 'triangle'}

# possible cues
COLOR_CUE = 'color'
SHAPE_CUE = 'shape'

COLOR_DATA_TEMPLATE = [
  {'condition': 'color', 'cue': COLOR_CUE, 'target': RED_RECTANGLE},
  {'condition': 'color', 'cue': COLOR_CUE, 'target': BLUE_TRIANGLE},
]

SHAPE_DATA_TEMPLATE = [
  {'condition': 'shape', 'cue': SHAPE_CUE, 'target': RED_RECTANGLE},
  {'condition': 'shape', 'cue': SHAPE_CUE, 'target': BLUE_TRIANGLE},
]

SHIFT_DATA_TEMPLATE = [
  {'condition': 'shift', 'cue': COLOR_CUE, 'target': RED_RECTANGLE},
  {'condition': 'shift', 'cue': SHAPE_CUE, 'target': BLUE_TRIANGLE},
  {'condition': 'shift', 'cue': SHAPE_CUE, 'target': RED_RECTANGLE},
  {'condition': 'shift', 'cue': SHAPE_CUE, 'target': BLUE_TRIANGLE},
]

# helper
objectsEqual = (obj1, obj2) ->
  return (obj1.color is obj2.color and obj1.shape is obj2.shape)

# create a generic trial block
#   colorFirst - whether to start with color trials (1=true; 0=false)
#   colorReps - number of times to repeat COLOR_DATA_TEMPLATE
#   shapeReps - number of times to repeat SHAPE_DATA_TEMPLATE
#   shiftReps - number of times to repeat SHIFT_DATA_TEMPLATE
createBlock = (colorFirst, colorReps, shapeReps, shiftReps) ->
  colorTrials = []
  colorCheckPassed = false
  shapeTrials = []
  shapeCheckPassed = false
  shiftTrials = []
  shiftCheckPassed = false
  
  if not colorFirst?
    colorFirst = _.random(0,1)
  
  if colorReps?
    colorTrialsInitial = _.flatten(COLOR_DATA_TEMPLATE for i in [0...colorReps])
    until colorCheckPassed
      colorTrials = Examiner.generateTrials(colorTrialsInitial, 1)
      colorCheckPassed = colorAndShapeCheck(colorTrials)

  if shapeReps?
    shapeTrialsInitial = _.flatten(SHAPE_DATA_TEMPLATE for i in [0...shapeReps])
    until shapeCheckPassed
      shapeTrials = Examiner.generateTrials(shapeTrialsInitial, 1)
      shapeCheckPassed = colorAndShapeCheck(shapeTrials)

  if shiftReps?
    shiftTrialsInitial = _.flatten(SHIFT_DATA_TEMPLATE for i in [0...shiftReps])
    until shiftCheckPassed
      shiftTrials = Examiner.generateTrials(shiftTrialsInitial, 1)
      shiftCheckPassed = shiftCheck(shiftTrials)

  finalTrials = []
  if colorFirst
    finalTrials = colorTrials.concat(shapeTrials)
  else
    finalTrials = shapeTrials.concat(colorTrials)

  if shiftReps?
    finalTrials = finalTrials.concat(shiftTrials)
    
  return finalTrials

# check to make sure the correct response is not the same response
# more than 4 times in a row for color and shape conditions
colorAndShapeCheck = (trials) ->
  respCount = 1
  lastTrial = _.first(trials)

  for trial in _.rest(trials)
    if lastTrial.target.color is trial.target.color
      respCount += 1
    else
      respCount = 1
    if respCount > 4
      return false
    lastTrial = trial

  return true

# check that the number of cue shifted trials is between 40% and 60%
# and there are no runs of cues > 4
shiftCheck = (trials) ->
  shiftCount = 0
  lastTrial = _.first(trials)
  cueCount = 1
  
  for trial in _.rest(trials)
    if lastTrial.cue is trial.cue
      cueCount += 1
    else
      shiftCount += 1
      cueCount = 1
    if cueCount > 4
      return false
    lastTrial = trial
  
  shiftPercentage = shiftCount / trials.length
  return (shiftPercentage >= 0.45 and shiftPercentage <= 0.55)


# return a practice block
createPracticeBlock = ->
  createBlock(1, 4, 4)
  #Examiner.generateTrials(TEST_TRIALS, 1, 'sequential')

# return a real testing block
createTestingBlock = ->
  createBlock(1, 10, 10, 16)
  #Examiner.generateTrials(TEST_TRIALS, 2, 'sequential')

# how many has the patient gotten correct in practice block?
numCorrectInPractice = 0

# which practice block are we on
numPracticeBlocks = 1

# have we passed the practice yet?
practicePassed = ->
  (numPracticeBlocks <= PRACTICE_MAX_BLOCKS \
    and numCorrectInPractice >= PRACTICE_MIN_CORRECT)

# start off in practice mode
inPracticeMode = true

# current trial block
# start off with a practice block
trialBlock = createTestingBlock()

# current trial in current trial block
trialIndex = -1

#pp(createTestingBlock())

showFeedback = (translation) ->
  $translation = $.t(translation)
  $fixationDiv = $('.fixationDiv')
  $fixationDiv.empty()
  $fixationDiv.html($translation)

hideFeedback = ->
  $('.fixationDiv').empty()

# heart of the task
showTrial = (trial) ->
  deferred = new $.Deferred()
  
  # resolved when user responds
  deferred.done((event, responseTime) ->
    hideTarget()
    hideCue()
    
    response = event.delegateTarget.alt
    if response is 'l'
      response = RED_TRIANGLE
    else
      response = BLUE_TRIANGLE
    
    correct = trial.target[trial.cue] is response[trial.cue]
      
    # record meaning of user response event
    interpretation =
      response: response
      responseTime: responseTime
      correct: correct

    TabCAT.Task.logEvent(getTaskState(), event, interpretation)

    if inPracticeMode
      if correct
        numCorrectInPractice += 1
        showFeedback 'feedback_correct'
      else
        showFeedback 'feedback_incorrect'
      
      TabCAT.UI.wait(FEEDBACK_DURATION).then(->
        hideFeedback()
        TabCAT.UI.wait(PRE_TRIAL_DELAY).then(->
          next()
        )
      )
    else
      TabCAT.UI.wait(PRE_TRIAL_DELAY).then(->
        next()
      )
  )
  
  # fails when user does not respond (i.e. trial times out)
  deferred.fail(->
    hideTarget()
    hideCue()
    
    # record meaning of the event
    interpretation =
      response: null
      responseTime: 0
      correct: false

    TabCAT.Task.logEvent(getTaskState(), "timeout", interpretation)

    if inPracticeMode
      showFeedback 'feedback_no_response'
      TabCAT.UI.wait(FEEDBACK_DURATION).then(->
        hideFeedback()
        next()
      )
    else
      next()
  )

  # start showing the trial
  
  TabCAT.UI.wait(PRE_TRIAL_DELAY).then(->
    if trial.cue = COLOR_CUE
      showCue('color_cue')
    else
      showCue('shape_cue')
    TabCAT.UI.wait(CUE_DURATION).then(->
      showFixation()
      TabCAT.UI.wait(FIXATION_DURATION).then(->
        hideFixation()
        showTarget(trial.target)
        # if user responds, then resolve
        $('.responseLeftImg, .responseRightImg') \
        .one('mousedown touchstart', (event) ->
          responseTime = 0
          event.preventDefault()
          event.stopPropagation()
          deferred.resolve(event, responseTime)
        )
        
        TabCAT.UI.wait(TARGET_DURATION).then(->
          #hideTarget()
        )
        
        # if trial times out, then reject
        TabCAT.UI.wait(TRIAL_TIMEOUT).then(->
          deferred.reject()
        )
      )
    )
  )

# primary task handler that controls entire flow of task
next = ->
  if trialIndex < trialBlock.length-1 # more trials in block
    trialIndex += 1
    showTrial(trialBlock[trialIndex])
  else # end of block
    if inPracticeMode
      if practicePassed() # passed practice so go to real testing
        inPracticeMode = false
        trialBlock = createTestingBlock()
        trialIndex = -1
        showInstructions 'testing_html'
      else if numPracticeBlocks is PRACTICE_MAX_BLOCKS # failed all 3 practices
        TabCAT.Task.finish()
      else # start new practice block
        trialBlock = createPracticeBlock()
        trialIndex = -1
        numCorrectInPractice = 0
        numPracticeBlocks += 1
        showInstructions 'additional_practice_html'
    else
      TabCAT.Task.finish()

# summary of current stimulus
getStimuli = ->
  trial = trialBlock[trialIndex]
  
  stimuli =
    condition: trial?.condition
    cue: trial?.cue
    target: trial?.target

  return stimuli

# summary of the current state of the task
getTaskState = ->
  state =
    trialNum: trialIndex
    stimuli: getStimuli()
    
  if inPracticeMode
    state.practiceMode = true
    state.trialBlock = "practiceBlock" + numPracticeBlocks
  else
    state.trialBlock = "testingBlock"

  if($('.instructions').is(':visible'))
    state.instructions = true

  return state

makeFixationDiv = ->
  $fixationDiv = $('<div></div>', class: 'fixationDiv')

showFixation = ->
  $fixationDiv = $('.fixationDiv')
  $fixationDiv.empty()
  $fixationDiv.text(FIXATION)

hideFixation = ->
  $('.fixationDiv').empty()

makeTargetDiv = ->
  $targetDiv = $('<div></div>', class: 'targetDiv')

showTarget = (obj) ->
  $targetDiv = $('.targetDiv')
  if objectsEqual(obj, RED_RECTANGLE)
    $img = $('<img>',
      class: 'targetImg',
      src: 'img/setshifting/rect_red.png')
  else
    $img = $('<img>',
      class: 'targetImg',
      src: 'img/setshifting/tri_blue.png')
  $targetDiv.append($img)

hideTarget = ->
  $('.targetDiv').empty()



# log stray taps
handleStrayTouchStart = (event) ->
  event.preventDefault()
  TabCAT.Task.logEvent(getTaskState(), event)

handleBeginButton = (event) ->
  event.preventDefault()
  event.stopPropagation()
  $rectangle = $('#rectangle')
  $rectangle.empty()
  $rectangle.append(makeResponseDiv)
  $rectangle.append(makeCueDiv)
  $rectangle.append(makeFixationDiv)
  $rectangle.append(makeTargetDiv)
  next()

handleNextButton = (event) ->
  event.preventDefault()
  event.stopPropagation()
  showInstructions 'practice2_html'

makeProgressButton = (translation, handler) ->
  $button = $('<button></button>', class: 'progressButton')
  $button.html($.t(translation))
  $button.one('mousedown touchstart', handler)
  $buttonDiv = $('<div></div>', class: 'progressButtonDiv')
  $buttonDiv.html($button)

makeResponseDiv = ->
  $responseDiv = $('<div></div>', class: 'responseDiv')
  $imgLeft = $('<img>',
    alt: 'l',
    class: 'responseImg responseLeftImg',
    src: 'img/setshifting/tri_red.png')
  $imgRight = $('<img>',
    alt: 'r',
    class: 'responseImg responseRightImg',
    src: 'img/setshifting/rect_blue.png')
  
  $responseDiv.append($imgLeft).append($imgRight)

makeCueDiv = ->
  $cueDiv = $('<div></div>', class: 'cueDiv')
  
showCue = (translation) ->
  $('.cueDiv').text($.t(translation))

hideCue = ->
  $('.cueDiv').empty()

showInstructions = (translation) ->
  $rectangle = $('#rectangle')
  $rectangle.empty()
  $instructions = $('<div></div>', class: 'instructions')

  $translation = $.t(translation, {returnObjectTrees: true})

  $html = switch translation
    when 'practice_html', 'practice2_html'
    then _.map($translation, (value, key) ->
      if (translation is 'practice_html' and key is '1') or
      (translation is 'practice2_html' and key is '2')
        value + '<br/>' +
        '<img class="instructionsImg" src="img/setshifting/rect_red.png"/>'
      else
        '<p>' + value + '</p>'
    )
    when 'additional_practice_html'
    then _.map($translation, (value, key) ->
      if key is '3' or key is '6'
        '<p><span style="float:left; margin-left: 10%">' + value + '</span>'
      else if key is '4' or key is '7'
        '<span style="float:right; margin-right: 10%">' +
        value + '</span></p><br/>'
      else if key is '5'
        '<img class="instructionsImg" src="img/setshifting/rect_red.png"/>' +
        '<p>' + value + '</p>'
      else
        '<p>' + value + '</p>'
    )
    when 'testing_html'
    then _.map($translation, (value, key) ->
      if key is '4'
        '<img class="instructionsImg" src="img/setshifting/rect_red.png"/>' +
        '<p>' + value + '</p>'
      else
        '<p>' + value + '</p>'
    )
    else []

  $html = $html.join('')
    
  $instructions.append("<p></p><p></p>" + $html)
  $instructions.appendTo($rectangle)
  
  $rectangle.append(makeResponseDiv)
  $rectangle.append(makeCueDiv)
  showCue('shape_cue')
  
  switch translation
    when 'practice_html'
      $rectangle.append(makeProgressButton('next_html', handleNextButton))
    when 'practice2_html', 'additional_practice_html', 'testing_html'
      $rectangle.append(makeProgressButton('begin_html', handleBeginButton))

# INITIALIZATION
@initTask = ->
  TabCAT.Task.start(
    i18n:
      resStore: translations
    trackViewport: true
  )
  
  TabCAT.UI.turnOffBounce()
  TabCAT.UI.enableFastClick()
  
  $(->
    $task = $('#task')
    $rectangle = $('#rectangle')
    
    $task.on('mousedown touchstart', handleStrayTouchStart)
    TabCAT.UI.fixAspectRatio($rectangle, ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)
    
    showInstructions 'practice_html'
  )

