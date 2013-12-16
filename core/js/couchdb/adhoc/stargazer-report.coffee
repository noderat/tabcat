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
_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')

MAX_REVERSALS = 18

patientHandler = (patientRecord) ->
  patientCode = patientRecord.patientCode

  for encounter in patientRecord.encounters
    for task in encounter.tasks
      if task.name is 'stargazer' and task.eventLog? and task.finishedAt?
        numTrials = _.max(
          item?.state?.trialNum ? null for item in task.eventLog)
        if numTrials?
          numTrials += 1

        end = task.finishedAt ? _.last(task.eventLog)?.now
        if task.startedAt? and end?
          totalTime = end - task.startedAt
        else
          totalTime = null

        # intensity is -(# stars), since more stars is harder
        starsAtReversal = (
          -item.state.intensity for item in task.eventLog \
          when item?.interpretation?.reversal)

        data = [patientCode, totalTime, numTrials].concat(
          starsAtReversal)

        send(csv.arrayToCsv([data]))

        # only keep the first task per patient
        return


exports.list = (head, req) ->
  keyType = req.path[req.path.length - 1]

  if not (req.path.length is 6 and keyType is 'patient')
    throw new Error('You may only dump the patient view')

  isoDate = (new Date()).toISOString().substring(0, 10)

  start(headers:
    'Content-Disposition': (
      "attachment; filename=\"stargazer-report-#{isoDate}.csv"),
    'Content-Type': 'text/csv')

  csvHeader = ['patientCode', 'time', 'trials'].concat(
    ('starsAtRev' + i for i in [1..MAX_REVERSALS]))
  send(csv.arrayToCsv([csvHeader]))

  patient.iterate(getRow, patientHandler)
