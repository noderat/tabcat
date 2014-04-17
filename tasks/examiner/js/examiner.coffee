
@Examiner ?= {}


Examiner.generateTrials = (trialList, numReps) ->
  if not numReps?
    numReps = 1
  else
    numReps = Math.max(1, numReps)
    


    
  constructor: (@numReps = 1, @trialList = TEST_TRIALS) ->
    @numReps = Math.max(1, @numReps)
    @trialListLength = @trialList.length
    @reset()
    
  reset: ->
    @currentRepNum = 0
    @currentTrialNum = -1
    @currentTrial = false
    @finished = false

    @sequenceIndices = @createSequence()
    
  createSequence: ->
    trialListIndices = _.range @trialListLength
    (_.shuffle trialListIndices for i in [0...@numReps])

  hasNext: ->
    not @end()
  
  end: ->
    (@currentRepNum is (@numReps-1) \
      and @currentTrialNum is (@trialListLength-1))

  next: ->
    @currentTrialNum += 1
    
    if @currentTrialNum is @trialListLength
      @currentTrialNum = 0
      @currentRepNum += 1
      
    if @currentRepNum >= @numReps
      @finished = true

    if @finished
      @currentTrial = false
    else
      index = @sequenceIndices[@currentRepNum][@currentTrialNum]
      @currentTrial = @trialList[index]

  # for debug
  getSequence: ->
    @sequenceIndices
    
  pp: ->
    pp(@sequenceIndices)