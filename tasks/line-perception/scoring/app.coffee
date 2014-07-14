###
Copyright (c) 2014, Regents of the University of California
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
patient = require('js/couchdb/patient')
Scoring = require('js/tabcat/scoring')
require('scoring')


scoreList = (head, req) ->
  dbAndView = req.path[-2..]

  if not (req.path.length is 7 and _.isEqual(dbAndView, ['core', 'patient']))
    throw new Error('You may only dump the patient view')

  start(headers:
    'Content-Type': 'application/json')

  taskIdToScore = {}

  patientHandler = (patientRecord) ->
    for encounter in patientRecord.encounters
      for task in encounter.tasks
        if task.finishedAt?
          taskIdToScore[task._id] = Scoring.scoreTask(task.name, task.eventLog)

  patient.iterate(getRow, patientHandler)

  send(JSON.stringify(taskIdToScore, null, 2))


exports.lists =
  score: scoreList
