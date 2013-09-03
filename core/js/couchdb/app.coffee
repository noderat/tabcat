# sort docs by patient, encounter, and task
#
# key is [patientCode, encounterId, taskId, encounterClockTime], with
# the last three fields optional.
patientMap = (doc) ->
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


# stitch together data from the patient view
dumpList = (head, req) ->
  _ = require('views/lib/underscore')._

  keyType = _.last(req.path)

  if not (req.path.length is 6 and keyType is 'patient')
    throw new Error('You may only dump the patient view')

  start(headers:
    'Content-Type': 'application/json')

  send('[\n')

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

    # handle start of new patient
    if (patientCode ? null) != (currentPatient?.patientCode ? null)
      if currentPatient?
        # sort encounters by encounterNum
        currentPatient.encounters = _.sortBy(
          encounters, (e) -> e.encounterNum)
        # add patient type (if missing), for clarity
        currentPatient.type ?= 'patient'

        # write the patient doc out
        send(JSON.stringify(currentPatient, null, 2))
        if row?
          send(',\n')

      currentPatient = if patientCode? then {patientCode: patientCode}
      encounters = []

    # if we've seen all the rows, we're done!
    if not row?
      send('\n]\n')
      return

    # reconstruct the document
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


exports.lists =
  dump: dumpList


exports.views =
  patient:
    map: patientMap
