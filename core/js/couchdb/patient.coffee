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

# sort docs by patient, encounter, and task
#
# key is [patientCode, encounterId, taskId, encounterClockTime], with
# the last three fields optional.
exports.map = (doc) ->
  switch doc.type
    when 'encounter'
      value =
        type: 'encounter'
        year: doc.year
      if doc.limitedPHI?
        value.limitedPHI =
          clockOffset: doc.limitedPHI?.clockOffset
      emit([doc.patientCode, doc._id], value)

    when 'eventLog'
      emit([doc.patientCode, doc.encounterId, doc.taskId, doc.items[0].now],
        startIndex: doc.startIndex
        endIndex: doc.startIndex + doc.items.length
        type: 'eventLog')

    when 'patient'
      # nothing worth indexing in patient right now
      # this is only useful for include_docs=true
      emit([doc.patientCode], type: 'patient')

      # calculate encounter number from patient.encounterIds
      if doc.encounterIds?
        for encounterId, i in doc.encounterIds
          # blank out _id so include_docs won't attach documents
          emit([doc.patientCode, encounterId],
            _id: ''
            encounterNum: i
            type: 'encounterNum')

    when 'task'
      emit([doc.patientCode, doc.encounterId, doc._id, doc.startedAt],
        name: doc.name,
        finishedAt: doc.finishedAt,
        type: 'task')


# a function that compiles the patient view into patient records
#
# getRow() takes no args returns the next row of the patient view, or null
# when the last is reached
#
# for each patient record we compile, we call handler with the patient
# as the sole argument
exports.iterate = (getRow, handler) ->
  _ = require('js/vendor/underscore')._

  currentPatient = null
  currentEncounter = null
  encounters = []
  currentTask = null
  tasks = []
  eventLog = []

  # going to go through this loop one last time when we hit the end of the data
  while true
    row = getRow()

    [patientCode, encounterId, taskId, startedAt] = row?.key ? []

    # skip docs with missing patient code or encounter ID
    if row?
      if not patientCode?
        continue
      if not encounterId? and row.value.type isnt 'patient'
        continue

    # handle start of new task
    if (taskId ? null) != (currentTask?._id ? null)
      if currentTask?
        if not _.isEmpty(eventLog)
          currentTask.eventLog ?= eventLog
        tasks.push(currentTask)

      currentTask = if taskId? then {_id: taskId}
      eventLog = []

    # handle start of new encounter
    if (encounterId ? null) != (currentEncounter?._id ? null)
      if currentEncounter?
        currentEncounter.tasks ?= _.sortBy(tasks, (t) -> t.startedAt)
        encounters.push(currentEncounter)

      currentEncounter = if encounterId? then {_id: encounterId}
      tasks = []

    # when we see a new patientCode, emit the last patient record
    if (patientCode ? null) != (currentPatient?.patientCode ? null)
      if currentPatient?
        # sort encounters by encounterNum
        currentPatient.encounters = _.sortBy(
          encounters, (e) -> e.encounterNum)
        # add patient type (if missing), for clarity
        currentPatient.type ?= 'patient'

        # emit the patient record
        handler(currentPatient)

      currentPatient = if patientCode? then {patientCode: patientCode}
      encounters = []

    # if we've seen all the rows, we're done!
    if not row?
      return

    # add the current row to the current patient record
    doc = _.extend(
      _id: row.id, startedAt: startedAt,
      _.omit(row.value, 'type'),
      row.doc)

    switch row.value.type
      when 'eventLog'
        if doc.items? and doc.startIndex?
          for item, i in doc.items
            eventLog[doc.startIndex + i] = item

      when 'encounter'
        _.extend(currentEncounter, doc)

      when 'encounterNum'
        currentEncounter.encounterNum = doc.encounterNum

      when 'patient'
        _.extend(currentPatient, doc)

      when 'task'
        # fix for old format where trialNum was 1-indexed
        if doc.eventLog? and doc.version in ['0.1.0', '0.2.0']
          for item in doc.eventLog
            if item.state?.trialNum?
              item.state.trialNum -= 1

        _.extend(currentTask, doc)
