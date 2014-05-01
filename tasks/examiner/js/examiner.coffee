
@Examiner ?= {}

# Generates a trial list based on a template trialList:
# - trialList: an array of objects representing a set of trials
# - numReps: number of repetitions to repeat the trialList
# - method: 'random' randomizes the trialList; 'sequential'
#   simply outputs the trialList as specified
Examiner.generateTrials = (trialList, numReps, method) ->
  if not numReps?
    numReps = 1
  else
    numReps = Math.max(1, numReps)
    
  if not method?
    method = 'random'
    
  if method is 'random'
    trialListIndices = _.range trialList.length
    allIndices = _.flatten(_.shuffle trialListIndices for i in [0...numReps])
    _.map(allIndices, (index) -> trialList[index])
  else if method is 'sequential'
    _.flatten(trialList for i in [0...numReps])
    
    