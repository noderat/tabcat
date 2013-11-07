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
# transform a dump of the patient list:
#
#  /tabcat-data/_design/core/_list/dump/patient?include_docs=true
#
# into a CSV with summary data for all completed line tasks
#
# usage: node line-tasks-report.js patient-list-dump.json > out.csv
csv = require('csv')
fs = require('fs')
JSONStream = require('JSONStream')
_ = require('underscore')._

NUM_REVERSALS = 20

LINE_TASKS = [
  'parallel-line-length',
  'perpendicular-line-length',
  'line-orientation'
]

COLUMNS_PER_TASK = NUM_REVERSALS + 3

stream = fs.createReadStream(process.argv[2], encoding: 'utf8')
parser = JSONStream.parse('*')
csvout = csv().to(process.stdout)

taskHeader = (prefix) ->
  [prefix + 'Time', prefix + 'Trials', prefix + 'TimePerTrial'].concat(
    (prefix + i for i in [1..NUM_REVERSALS]))

header = ['patientCode'].concat(
  taskHeader('Par')).concat(
  taskHeader('Prp')).concat(
  taskHeader('LO'))

csvout.write(header)


parser.on('data', (patient) ->
  patientCode = patient.patientCode

  taskToInfo = {}
  for encounter in patient.encounters
    for task in encounter.tasks
      if task.finishedAt and task.name in LINE_TASKS
        # only keep the first task per patient
        if taskToInfo[task.name]
          continue

        # this isn't an off-by one; we discard the first trial because we
        # don't know when the patient first gets the task
        # using ? null because _.max() handles undefined differently
        numTrials = _.max(
          item?.state?.trialNum ? null for item in task.eventLog)

        firstAction = _.find(task.eventLog, (item) -> item?.interpretation?)
        totalTime = (task.finishedAt - firstAction.now) / 1000

        # use the "interpretation" field if we have it (phasing this out)
        intensitiesAtReversal = task?.interpretation?.intensitiesAtReversal

        if not intensitiesAtReversal?
          intensitiesAtReversal = (
            item.state.intensity for item in task.eventLog \
            when item?.interpretation?.reversal)

        taskToInfo[task.name] =
          totalTime: totalTime
          numTrials: numTrials
          timePerTrial: totalTime / numTrials
          intensitiesAtReversal: intensitiesAtReversal

  if _.isEmpty(taskToInfo)
    return

  data = []

  data[0] = patientCode
  for taskName, i in LINE_TASKS
    info = taskToInfo[taskName]
    if info?
      offset = i * COLUMNS_PER_TASK + 1
      data[offset] = info.totalTime
      data[offset + 1] = info.numTrials
      data[offset + 2] = info.timePerTrial
      for intensity, j in info.intensitiesAtReversal
        data[offset + 3 + j] = intensity

  csvout.write(data)
)

stream.pipe(parser)
