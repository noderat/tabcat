
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
           'tap it as quickly as you can.<br/>' +
           'If any other shape is presented, do not tap anything.'
        2: 'Respond as quickly as you can without making mistakes.<br/>' +
           'If you do make a mistake just keep going.'
        3: 'We will start with some practice trials.'
      additional_practice_html:
        1: 'You have completed the practice trial.<br/>' +
           'Let\'s do another practice trial.'
        2: 'The instructions are the same.<br/>' +
           'You will be presented with different shapes on the screen.<br/>' +
           'If the $t(object_version) is presented on the screen,<br/>' +
           'tap it as quickly as you can.<br/>' +
           'If any other shape is presented, do not anything.'
        3: 'Respond as quickly as you can without making mistakes.<br/>' +
           'If you do make a mistake just keep going.'
      testing_html:
        1: 'You have completed the practice trial.<br/>' +
           'Let\'s move on to the task.'
        2: 'The instructions are the same.<br/>' +
           'You will be presented with different shapes on the screen.<br/>' +
           'If the $t(object_version) is presented on the screen,</br>' +
           'tap it as quickly as you can.<br/>' +
           'If any other shape is presented, do not tap anything.'
        3: 'Respond as quickly as you can without making mistakes.<br/>' +
           'If you do make a mistake just keep going.'
      object_version_a:
        '5-POINTED STAR'
      object_version_b:
        'LEFT ARROW'
      object_version_c:
        'white TRIANGLE'

# task version (one of a, b, c)
# defaults to 'a' but set pseudo-randomly in initTask
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
  {'stimulus': 'nontarget1', 'filename': 'nt1.svg'},
  {'stimulus': 'nontarget2', 'filename': 'nt2.svg'},
  {'stimulus': 'nontarget3', 'filename': 'nt3.svg'},
  {'stimulus': 'nontarget4', 'filename': 'nt4.svg'},
  {'stimulus': 'nontarget5', 'filename': 'nt5.svg'}
].concat(
  ({'stimulus': 'target', 'filename': 'target.svg'} \
    for i in [0...PRACTICE_NUM_TARGETS])
)

# total of 25 trials (5 non targets, 20 targets)
REAL_TRIALS = [
  {'stimulus': 'nontarget1', 'filename': 'nt1.svg'},
  {'stimulus': 'nontarget2', 'filename': 'nt2.svg'},
  {'stimulus': 'nontarget3', 'filename': 'nt3.svg'},
  {'stimulus': 'nontarget4', 'filename': 'nt4.svg'},
  {'stimulus': 'nontarget5', 'filename': 'nt5.svg'}
].concat(
  ({'stimulus': 'target', 'filename': 'target.svg'} \
    for i in [0...REAL_NUM_TARGETS])
)

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

makeStimulusDiv = ->
  $stimulusDiv = $('<div></div>', class: 'stimulusDiv')

# heart of the task
showTrial = (trial) ->
  trialStartTime = $.now()
  responses = [] # keep track of all responses
  responseEvent = null # event to log

  $stimulusDiv = $('.stimulusDiv')
  $img = $('<img>',
    alt: trial.stimulus,
    class: 'stimulusImg',
    src: 'img/cpt/' + CPT_VERSION + '/' + trial.filename)
  $img.on('mousedown touchstart', (event) ->
    responseTime = ($.now() - trialStartTime) / 1000
    event.preventDefault()
    event.stopPropagation()
    responses.push(responseTime)
    responseEvent = event
  )
  $stimulusDiv.append($img)

  TabCAT.UI.wait(STIMULUS_DISPLAY_DURATION).then(->
    # do this instead of hiding or removing so we can continue
    # recording responses on the img after stimulus goes away
    $img.css('opacity', 0)
  )

  # All responses are recorded after the display of the stimulus.
  # The first response after the display of the stimulus is recorded
  # in terms of the response time. Any additional responses prior to the
  # next stimulus display are recorded and result in an "incorrect"
  # response score for the trial.
  registerResponses = (
    # only allow this much time to respond
    TabCAT.UI.wait(RESPONSE_TIME_LIMIT).then(->
      # disable responses by removing the img
      $('.stimulusDiv').empty()

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

handleBeginClick = (event) ->
  event.preventDefault()
  event.stopPropagation()

  $rectangle = $('#rectangle')
  $rectangle.empty()
  $rectangle.append(makeStimulusDiv())

  # wait before display of initial trial in the block
  TabCAT.UI.wait(BEFORE_BLOCK_DELAY + INTER_STIMULUS_DELAY).then(->
    next()
  )

makeBeginButton = ->
  $button = $('<button></button>', class: 'beginButton')
  $button.html($.t('begin_html'))
  $button.one('mousedown touchstart', handleBeginClick)
  $buttonDiv = $('<div></div>', class: 'beginButtonDiv')
  $buttonDiv.html($button)

showInstructions = (translation) ->
  $rectangle = $('#rectangle')
  $rectangle.empty()
  $instructions = $('<div></div>', class: 'instructions')

  $translation = $.t(translation, \
    {returnObjectTrees: true, context: CPT_VERSION})

  $html = switch translation
    when 'practice_html', 'additional_practice_html' \
    then _.map($translation, (value, key) ->
      if (translation is 'practice_html' and key is '1') or
      (translation is 'additional_practice_html' and key is '2')
        '<p>' + value + '<br/></br>' +
        '<img class="stimuli" src="img/cpt/'+CPT_VERSION+'/target.svg"/></p>'
      else
        '<p>' + value + '</p>'
    )
    when 'testing_html' then _.map($translation, (value, key) ->
      '<p>' + value + '</p>'
    )
    else []


  $html = $html.join('')

  $instructions.append("<p></p>" + $html)
  $instructions.appendTo($rectangle)

  $rectangle.append(makeBeginButton())

# log stray taps
handleStrayTouchStart = (event) ->
  event.preventDefault()
  TabCAT.Task.logEvent(getTaskState(), event)

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
    # pseudo-randomly select version based on encounter num
    encounterNum = TabCAT.Encounter.getNum()
    if encounterNum
      CPT_VERSION = switch (encounterNum % 3)
        when 0 then 'c'
        when 1 then 'a'
        when 2 then 'b'

    $task = $('#task')
    $rectangle = $('#rectangle')

    $task.on('mousedown touchstart', handleStrayTouchStart)
    TabCAT.UI.fixAspectRatio($rectangle, ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)

    showInstructions 'practice_html'
  )
