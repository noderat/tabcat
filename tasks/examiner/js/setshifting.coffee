
translations =
  en:
    translation:
      begin_html:
        'Begin'
      practice_html:
        1: 'This is a matching task.</br>' +
           'You will see an object in the center of the screen, and a word' +
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
        2: 'Tap the "Begin" button to begin'
      additional_practice_html:
        1: 'You have completed the practice trial. ' +
           'Let\'s do another practice trial.'
        2: 'You will be shown a series of arrows on the screen, ' +
           'pointing to the left or to the right. For example:'
        3: 'or'
        4: 'Press the RIGHT button if the CENTER arrow ' +
           'points to the right.</br>' +
           'Press the LEFT button if the CENTER arrow ' +
           'points to the left.'
        5: 'Try to respond as quickly and accurately as you can.'
        6: 'Try to keep your attention focused on the ' +
           'cross ("+") at the center of the screen.'
        7: 'Tap the "Begin" button when you are ready to begin.'
      testing_html:
        1: 'Now we\'ll move on to the task, the instructions are ' +
           'the same except you will no longer receive feedback ' +
           'after your responses.</br>'
        2: 'Press the LEFT button if the CENTER arrow ' +
           'points to the left.'
        3: 'Press the RIGHT button if the CENTER arrow ' +
           'points to the right.</br>'
        4: 'Remember to keep your focus on the center cross ("+") and try to ' +
           'respond as quickly as possible without making mistakes.'
        5: 'Tap the "Begin" button when you are ready to begin.'
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


TEST_TRIALS = [
  {'arrows':'lllll', 'upDown':'up'  },
  {'arrows':'lllll', 'upDown':'down'},
  {'arrows':'rrrrr', 'upDown':'up'  },
]

DEFAULT_TRIALS = [
  {'arrows':'lllll', 'upDown':'up'  },
  {'arrows':'lllll', 'upDown':'down'},
  {'arrows':'rrrrr', 'upDown':'up'  },
  {'arrows':'rrrrr', 'upDown':'down'},
  {'arrows':'llrll', 'upDown':'up'  },
  {'arrows':'llrll', 'upDown':'down'},
  {'arrows':'rrlrr', 'upDown':'up'  },
  {'arrows':'rrlrr', 'upDown':'down'},
]

# For each trial, the correct response is the middle arrow,
# or arrow at index 2 (i.e. for 'llrll', correct answer is 'r')
CORRECT_ARROW_INDEX = 2

# pre trial delay of 0.4 seconds in practice blocks
# (time between response and next fixation)
PRACTICE_PRE_TRIAL_DELAY = 400

# In practice trials, feedback is displayed to subject
# about their responses for 2 seconds
PRACTICE_FEEDBACK_DISPLAY_DURATION = 2000

# If the subject gets 6 out of 8 trials correct in a practice trial then
# skip ahead to the real testing trial. If the subject fails to get
# 6 out of 8 in 3 practice blocks then end the task.
PRACTICE_MIN_CORRECT = 6

# Max number of practice blocks to try before aborting task
PRACTICE_MAX_BLOCKS = 3

# Displays fixation stimuli for at least 1 second and
# no more than 3 seconds (random)
FIXATION_PERIOD_MIN = 1000
FIXATION_PERIOD_MAX = 3000

# pre trial delay of 0.2 seconds in real testing
# (time between response and next fixation)
PRE_TRIAL_DELAY = 200

# trial stimuli is displayed for 4 seconds or until subject
# provides a keyboard response
STIMULI_DISPLAY_DURATION = 4000

# main div's aspect ratio (pretend we're on an iPad)
ASPECT_RATIO = 4/3

# return a practice block
createPracticeBlock = ->
  Examiner.generateTrials(DEFAULT_TRIALS, 1)
  #Examiner.generateTrials(TEST_TRIALS, 1, 'sequential')

# return a real testing block
createTestingBlock = ->
  Examiner.generateTrials(DEFAULT_TRIALS, 2)
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
trialBlock = createPracticeBlock()

# current trial in current trial block
trialIndex = -1

# current fixation duration for current trial
fixationDuration = null

# for debugging
pp = (msg) ->
  $('#debug').append(JSON.stringify(msg)).append('</br>')

showFixation = ->
  $('#fixation').show()

showArrow = (arrows, upDown) ->
  $('#' + arrows + '_' + upDown).show()

hideArrow = (arrows, upDown) ->
  $('#' + arrows + '_' + upDown).hide()

clearStimuli = ->
  $stimuli = $('#stimuli')
  $stimuli.children().hide()

showBeginButton = ->
  hideResponseButtons()
  $beginButton = $('#beginButton')
  $beginButton.one('mousedown touchstart', handleBeginClick)
  $beginButton.show()

hideBeginButton = ->
  $('#beginButton').hide()
    
showResponseButtons = ->
  hideBeginButton()
  $responseButtons = $('#leftResponseButton, #rightResponseButton')
  $responseButtons.show()

hideResponseButtons = ->
  $('#leftResponseButton, #rightResponseButton').hide()

enableResponseButtons = ->
  $responseButtons = $('#leftResponseButton, #rightResponseButton')
  $responseButtons.prop('disabled',false)
  
disableResponseButtons = ->
  $responseButtons = $('#leftResponseButton, #rightResponseButton')
  $responseButtons.prop('disabled',true)

# method not currently used
responseButtonsEnabled = ->
  !$('#leftResponseButton').prop('disabled')

showInstructions = (translation) ->
  clearStimuli()
  $translation = $.t(translation, {returnObjectTrees: true})

  $html = switch translation
    when 'practice_html', 'practice2_html'
    then _.map($translation, (value, key) ->
      if (translation is 'practice_html' and key is '1') or
      (translation is 'practice2_html' and key is '2')
        value + '<br/>' +
        '<img class="instructionsArrow" src="img/setshifting/rect_red.png"/>'
      else
        '<p>' + value + '</p>'
    )
    when 'testing_html' then _.map($translation, (value, key) ->
      '<p>' + value + '</p>'
    )
    else []

  $html = $html.join('')
    
  switch translation
    when 'practice_html', 'practice2_html'
    then $html = $html +
      '<div class="practiceStim">' +
      '<img class="practiceStimLeft" src="img/setshifting/tri_red.png"/>' +
      '<img class="practiceStimRight" src="img/setshifting/rect_blue.png"/>' +
      '<span class="practiceStimText">' + $.t('shape_cue') + '</span>' +
      '</div>'

  $instructions = $('#instructions')
  $instructions.html("<p></p><p></p>" + $html)
  $instructions.show()

showFeedback = (translation) ->
  clearStimuli()
  $translation = $.t(translation)
  
  $html = switch translation
    when 'feedback_correct' \
      then '<span class="blue">' + $translation + '</span>'
    when 'feedback_incorrect', 'feedback_no_response' \
      then '<span class="red">' + $translation + '</span>'
    else translation

  $feedback = $('#feedback')
  $feedback.html($html)
  $feedback.show()

hideFeedback = ->
  $('#feedback').hide()

# is user response correct
isCorrect = (arrows, response) ->
  arrows.charAt(CORRECT_ARROW_INDEX) is response
  
# can assume arrows are congruent if the middle
# two characters are the same
isCongruent = (arrows) ->
  return arrows.charAt(CORRECT_ARROW_INDEX) is \
    arrows.charAt(CORRECT_ARROW_INDEX+1)

# heart of the task
showTrial = (trial) ->
  deferred = new $.Deferred()
  
  # resolved when user responds
  deferred.done((event, responseTime) ->
    disableResponseButtons()
    clearStimuli()
    
    response = event.delegateTarget.value
    correct = isCorrect(trial.arrows, response)
      
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
      
      TabCAT.UI.wait(PRACTICE_FEEDBACK_DISPLAY_DURATION).then(->
        hideFeedback()
        TabCAT.UI.wait(PRACTICE_PRE_TRIAL_DELAY).then(->
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
    disableResponseButtons()
    hideArrow(trial.arrows, trial.upDown)
      
    # record meaning of the event
    interpretation =
      response: null
      responseTime: 0
      correct: false

    TabCAT.Task.logEvent(getTaskState(), "timeout", interpretation)

    if inPracticeMode
      showFeedback 'feedback_no_response'
      TabCAT.UI.wait(PRACTICE_FEEDBACK_DISPLAY_DURATION).then(->
        hideFeedback()
        next()
      )
    else
      next()
  )

  # start showing the trial
  fixationDuration = _.random(FIXATION_PERIOD_MIN, FIXATION_PERIOD_MAX)
  showFixation()
  
  TabCAT.UI.wait(fixationDuration).then(->
    enableResponseButtons()
    trialStartTime = $.now()
    showArrow(trial.arrows, trial.upDown)
    
    # if user responds, then resolve
    $('#leftResponseButton, #rightResponseButton') \
    .one('mousedown touchstart', (event) ->
      responseTime = $.now() - trialStartTime
      event.preventDefault()
      event.stopPropagation()
      deferred.resolve(event, responseTime)
    )

    # if trial times out, then reject
    TabCAT.UI.wait(STIMULI_DISPLAY_DURATION).then(->
      deferred.reject()
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
        showBeginButton()
      else if numPracticeBlocks is PRACTICE_MAX_BLOCKS # failed all 3 practices
        TabCAT.Task.finish()
      else # start new practice block
        trialBlock = createPracticeBlock()
        trialIndex = -1
        numCorrectInPractice = 0
        numPracticeBlocks += 1
        showInstructions 'additional_practice_html'
        showBeginButton()
    else
      TabCAT.Task.finish()

handleBeginClick = (event) ->
  event.preventDefault()
  event.stopPropagation()
  clearStimuli()
  showResponseButtons()
  disableResponseButtons()
  next()

# summary of current stimulus
getStimuli = ->
  trial = trialBlock[trialIndex]
  
  stimuli =
    arrows: trial.arrows
    upDown: trial.upDown
    congruent: isCongruent(trial.arrows)
    fixationDuration: fixationDuration

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

  if($('#instructions').is(':visible'))
    state.instructions = true

  return state

# log stray taps
handleStrayTouchStart = (event) ->
  event.preventDefault()
  TabCAT.Task.logEvent(getTaskState(), event)

# load initial screen
showStartScreen = ->
  showInstructions 'practice2_html'
  $('#beginButton').html($.t('begin_html'))
  showBeginButton()

# load the stimuli imgs
loadStimuli = ->
  # create the arrow imgs
  $imgs = _.map(DEFAULT_TRIALS, (trial) ->
    '<img id="' + trial.arrows + '_' + \
      (if trial.upDown is 'up' then 'up' else 'down') + \
      '" src="img/flanker/' + trial.arrows + '.png" ' + \
      'style="display:none" ' + \
      'class="arrow center ' + \
      (if trial.upDown is 'up' then 'aboveFixation"' else 'belowFixation"') + \
      '>')
  
  # create fixation img
  $imgs = $imgs.join('') + '<img id="fixation" ' + \
    'src="img/flanker/fixation.png" ' + \
    'class="center fixation" ' +\
    'style="display:none">'

  $('#stimuli').append($imgs)

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
    
    loadStimuli()
    disableResponseButtons()
    showStartScreen()
  )

