
# If the subject gets 16 out of 20 trials correct in a practice trial
# then skip ahead to the real testing trial.
# If the subject fails to get 16 out of 20 in 3 practice blocks
# then end the task.

# The CPT block runs a set number of trials (randomly ordered) and
# each trial has the following structure:
#   1) Stimulus Display: 750 milliseconds
#   2) Interstimulus Interval: 1500 milliseconds
#   3) Response Time Limit: 2 seconds (from when trial begins)
#   4) Trial Timeout = Stimulus Display + Interstimulus Interval
# Each block has the following structure:
#   1) Number of targets in block: Default is 20, practice trials is 15
#   2) The trials are handled to ensure that there are no sequences
#      of targets longer than 10 and no sequences of nontargets longer than 2.
#   3) One second delay before each block
    
# All responses are recorded after the display of the stimulus.
# The first response after the display of the stimulus is recorded
# in terms of the response time.
# Any additional responses prior to the next stimulus display
# are recorded and result in an "incorrect" response score for the trial.

translations =
  en:
    translation:
      begin_html:
        'Begin'
      practice_html:
        1: 'You will be presented with different objects ' +
           'on the screen.<br/>' +
           'If this $t(object_version) is presented on the screen,</br>' +
           'tap the button at the bottom of the screen.<br/>' +
           'If any other shape is presented, do not press any key.'
        2: 'Respond as quickly as you can without making mistakes.<br/>' +
           'If you do make a mistake just keep going.'
        3: 'We will start with some practice trials.</br>' +
           'Tap the "Begin" button to begin.'
      additional_practice_html:
        1: 'You have completed the practice trial.<br/>' +
           'Let\'s do another practice trial.'
        2: 'The instructions are the same.<br/>' +
           'You will be presented with different shapes on the screen.<br/>' +
           'If the $t(object_version) is presented on the screen,<br/>' +
           'tap the button at the bottom of the screen.<br/>' +
           'If any other shape is presented, do not press any key.'
        3: 'Respond as quickly as you can without making mistakes.<br/>' +
           'If you do make a mistake just keep going.'
        4: 'Tap the "Begin" button to begin.'
      testing_html:
        1: 'You have completed the practice trial.<br/>' +
           'Let\'s move on to the task.'
        2: 'The instructions are the same.<br/>' +
           'You will be presented with different shapes on the screen.<br/>' +
           'If the $t(object_version) is presented on the screen,</br>' +
           'press the left arrow key.<br/>' +
           'If any other shape is presented, do not press any key.'
        3: 'Respond as quickly as you can without making mistakes.<br/>' +
           'If you do make a mistake just keep going.'
        4: 'Tap the "Begin" button to begin.'
      object_version_a:
        '5-POINTED STAR'
      object_version_b:
        'LEFT ARROW'
      object_version_c:
        'white TRIANGLE'

# task version (one of a, b, c)
CPT_VERSION = 'a'

# time to display the stimulus
STIMULUS_DISPLAY_DURATION = 750

# time between stimulus erasure and next trial display
INTER_STIMULUS_DELAY = 1500

# duration before trial times out
TRIAL_TIMEOUT = STIMULUS_DISPLAY_DURATION + INTER_STIMULUS_DELAY

# one second delay before each block
BEFORE_BLOCK_DELAY = 1000

# duration of time responses are allowed beginning from stimulus display
RESPONSE_TIME_LIMIT = 2000

# number of targets during real testing (20)
REAL_NUM_TARGETS = 20

# number of targets during practice (15)
PRACTICE_NUM_TARGETS = 15

# If subjects gets 16/20 trials correct in a practice trial
# then skip ahead to real testing. If subjects fails get this
# number correct in 3 practice blocks then end the task
PRACTICE_MIN_CORRECT = 16

# Max number of practice blocks to try before aborting task
PRACTICE_MAX_BLOCKS = 3

# main div's aspect ratio (pretend we're on an iPad)
ASPECT_RATIO = 4/3

# total of 20 trials (5 non targets, 15 targets)
PRACTICE_TRIALS = [
  {'stimulus': 'nontarget1'},
  {'stimulus': 'nontarget2'},
  {'stimulus': 'nontarget3'},
  {'stimulus': 'nontarget4'},
  {'stimulus': 'nontarget5'}
].concat(({'stimulus': 'target'} for i in [0...PRACTICE_NUM_TARGETS]))

# total of 25 trials (5 non targets, 20 targets)
REAL_TRIALS = [
  {'stimulus': 'nontarget1'},
  {'stimulus': 'nontarget2'},
  {'stimulus': 'nontarget3'},
  {'stimulus': 'nontarget4'},
  {'stimulus': 'nontarget5'}
].concat(({'stimulus': 'target'} for i in [0...REAL_NUM_TARGETS]))


# for debugging
pp = (msg) ->
  $debug = $('#debug')
  if Object.prototype.toString.call(msg) is '[object Array]'
    $debug.append('</br>' + JSON.stringify(val) for val in msg)
  else
    $debug.append(JSON.stringify(msg,null,4)).append('</br>')

# create a generic block with sequencing checked by cptSequenceCheck()
createBlock = (trials, reps) ->
  cptTrials = null
  cptSequenceCheckPassed = false
  
  until cptSequenceCheckPassed
    cptTrials = Examiner.generateTrials(trials, reps)
    cptSequenceCheckPassed = cptSequenceCheck(cptTrials)

  return cptTrials

# utility method to validate sequence ordering of trials
# trials should have no sequences of targets longer than 10
# and no sequences of nontargets longer than 2
cptSequenceCheck = (trials) ->
  targetSequence = 0
  nontargetSequence = 0
  
  for trial in trials
    if trial.stimulus is 'target'
      targetSequence += 1
      nontargetSequence = 0
      if targetSequence > 10
        return false
    else
      nontargetSequence += 1
      targetSequence = 0
      if nontargetSequence > 2
        return false

  return true

# return a practice block
createPracticeBlock = ->
  createBlock(PRACTICE_TRIALS, 1)
  #Examiner.generateTrials(PRACTICE_TRIALS, 1, 'sequential')

# return a real testing block
createTestingBlock = ->
  createBlock(REAL_TRIALS, 4)
  #Examiner.generateTrials(REAL_TRIALS, 1, 'sequential')

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

clearStimuli = ->
  $stimuli = $('#stimuli')
  $stimuli.children().hide()

showBeginButton = ->
  hideResponseButton()
  $beginButton = $('#beginButton')
  $beginButton.one('mousedown touchstart', handleBeginClick)
  $beginButton.show()

hideBeginButton = ->
  $('#beginButton').hide()
    
showResponseButton = ->
  hideBeginButton()
  $('#responseButton').show()

hideResponseButton = ->
  $('#responseButton').hide()

enableResponseButton = ->
  $('#responseButton').prop('disabled',false)
  
disableResponseButton = ->
  $('#responseButton').prop('disabled',true)

showInstructions = (translation) ->
  clearStimuli()
  $translation = $.t(translation, \
    {returnObjectTrees: true, context: CPT_VERSION})

  $html = switch translation
    when 'practice_html', 'additional_practice_html' \
    then _.map($translation, (value, key) ->
      if (translation is 'practice_html' and key is '1') or
      (translation is 'additional_practice_html' and key is '2')
        '<p>' + value + '<br/></br>' +
        '<img class="stimuli" src="img/cpt/'+CPT_VERSION+'/target.png"/></p>'
      else
        '<p>' + value + '</p>'
    )
    when 'testing_html' then _.map($translation, (value, key) ->
      '<p>' + value + '</p>'
    )
    else []

  $instructions = $('#instructions')
  $instructions.html("<p></p><p></p>" + $html.join(''))
  $instructions.show()

showStimulus = (trial) ->
  $stim = $('#' + trial.stimulus)
  $stim.show()
  TabCAT.UI.wait(STIMULUS_DISPLAY_DURATION).then(->
    $stim.hide()
  )

# heart of the task
showTrial = (trial) ->
  trialStartTime = $.now()
  responses = [] # keep track of all responses
  responseEvent = null # event to log
  
  $('#responseButton').on('mousedown touchstart', (event) ->
    responseTime = ($.now() - trialStartTime) / 1000
    event.preventDefault()
    event.stopPropagation()
    responses.push(responseTime)
    responseEvent = event
  )
  
  enableResponseButton()
  showStimulus(trial)
 
  # All responses are recorded after the display of the stimulus.
  # The first response after the display of the stimulus is recorded
  # in terms of the response time. Any additional responses prior to the
  # next stimulus display are recorded and result in an "incorrect"
  # response score for the trial.
  registerResponses = (
    # only allow this much time to respond
    TabCAT.UI.wait(RESPONSE_TIME_LIMIT).then(->
      disableResponseButton()
  
      # once disabled can analyze and log responses
      extraResponses = 'none'
      if responses.length is 0
        responseTime = 0
        if trial.stimulus is 'target'
          correct = false
        else
          correct = true
      else if responses.length is 1
        responseTime = responses[0]
        if trial.stimulus is 'target'
          correct = true
        else
          correct = false
      else # more than one response for this trial
        correct = false # more than one response means automatically incorrect
        responseTime = _.first(responses)
        extraResponses = '[' + responses.toString() + ']'
      
      if inPracticeMode
        if correct
          numCorrectInPractice += 1
          
      interpretation =
        correct: correct
        responseTime: responseTime
        extraResponses: extraResponses

      return {responseEvent: responseEvent, interpretation: interpretation}
    )
  )
  
  # wait this long before going to next trial
  trialDone = (
    TabCAT.UI.wait(TRIAL_TIMEOUT).then(->
      return $.Deferred().resolve()
    )
  )
  
  $.when(registerResponses, trialDone).done((obj) ->
    TabCAT.Task.logEvent(getTaskState(), obj.responseEvent, obj.interpretation)
    next()
  )

# primary task handler that controls the entire flow
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
  showResponseButton()
  disableResponseButton()
  
  # wait before display of initial trial in the block
  TabCAT.UI.wait(BEFORE_BLOCK_DELAY + INTER_STIMULUS_DELAY).then(->
    next()
  )

# summary of current stimulus
getStimuli = ->
  trial = trialBlock[trialIndex]
  
  stimuli =
    stimulus: trial?.stimulus

  return stimuli

# summary of the current state of the task
getTaskState = ->
  state =
    version: CPT_VERSION
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
  showInstructions 'practice_html'
  $('#beginButton').html($.t('begin_html'))
  showBeginButton()

# load the stimuli imgs
loadStimuli = ->
  # create the non target imgs
  $imgs = _.map([1,2,3,4,5], (num) ->
    '<img id="nontarget' + num + '" ' + \
      'src="img/cpt/' + CPT_VERSION + '/nt' + num + '.png" ' + \
      'style="display:none" ' + \
      'class="nontarget">')
  
  # create the target img
  $imgs = $imgs.join('') + '<img id="target" ' + \
    'src="img/cpt/' + CPT_VERSION + '/target.png" ' + \
    'class="target" ' +\
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
    disableResponseButton()
    showStartScreen()
  )

