csv = require('csv')
fs = require('fs')
JSONStream = require('JSONStream')
_ = require('underscore')._

LINE_TASKS = [
  'parallel-line-length',
  'perpendicular-line-length',
  'line-orientation'
]

stream = fs.createReadStream(process.argv[2], encoding: 'utf8')
parser = JSONStream.parse('*.encounters.*')
csvout = csv().to(process.stdout)

csvout.write([
  'patientCode', 'encounterNum', 'taskName',
  'totalTime', 'numTrials', 'timePerTrial',
  'intensitiesAtReversal'])


parser.on('data', (encounter) ->
  for task in encounter.tasks
    if task.finishedAt and task.name in LINE_TASKS
      # this isn't an off-by one; we discard the first trial because we
      # don't know when the patient first gets the task
      # using ? null because _.max() handles undefined differently
      numTrials = _.max(item.state?.trialNum ? null for item in task.eventLog)
      firstAction = _.find(task.eventLog, (item) -> item.interpretation?)
      totalTime = (task.finishedAt - firstAction.now) / 1000
      timePerTrial = totalTime / numTrials
      intensitiesAtReversal = (
        item.state.intensity for item in task.eventLog \
        when item.interpretation?.reversal)

      csvout.write([
        encounter.patientCode,
        encounter.encounterNum,
        task.name,
        totalTime,
        numTrials,
        timePerTrial,
      ].concat(intensitiesAtReversal))
)

stream.pipe(parser)
