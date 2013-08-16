# group docs by encounter ID, and order chronologically
#
# key is [encounterId, encounterClockTime, docType]
#
# encounterNum is in the value emitted by the patient doc
encounterMap = (doc) ->
  switch doc.type
    when 'encounter'
      emit([doc._id, 0, 'encounter'],
        patientCode: doc.patientCode,
        limitedPHI:
          clockOffset: doc.limitedPHI?.clockOffset)
    when 'eventLog'
      emit([doc.encounterId, doc.items[0].now, 'eventLog'],
        taskId: doc.taskId,
        startIndex: doc.startIndex,
        endIndex: doc.startIndex + doc.items.length)
    when 'patient'
      if doc.encounterIds?
        for encounterId, i in doc.encounterIds
          emit([encounterId, null, 'patient'],
            encounterNum: i + 1,
            patientCode: doc.patientCode)
    when 'task'
      emit([doc.encounterId, doc.startedAt, 'task'],
        name: doc.name,
        finishedAt: doc.finishedAt)


# group docs by patient code and enounter ID
#
# key is [patientCode, encounterId, encounterClockTime, docType]
patientMap = (doc) ->
  switch doc.type
    when 'encounter'
      emit([doc.patientCode, doc._id, 0, 'encounter'],
        limitedPHI:
          clockOffset: doc.limitedPHI?.clockOffset)
    when 'eventLog'
      emit([doc.patientCode, doc.encounterId, doc.items[0].now, 'eventLog'],
        taskId: doc.taskId,
        startIndex: doc.startIndex,
        endIndex: doc.startIndex + doc.items.length)
    when 'patient'
      emit([doc.patientCode, null, null, 'patient'],
        encounterIds: doc.encounterIds)
    when 'task'
      emit([doc.patientCode, doc.encounterId, doc.startedAt, 'task'],
        name: doc.name,
        finishedAt: doc.finishedAt)


# group docs by task ID, and order chronologically
#
# key is [taskId, encounterClockTime, docType]
taskMap = (doc) ->
  switch doc.type
    when 'eventLog'
      emit([doc.taskId, doc.items[0].now, 'eventLog'],
        startIndex: doc.startIndex,
        endIndex: doc.startIndex + doc.items.length)
    when 'task'
      emit([doc._id, doc.startedAt, 'task'],
        name: doc.name,
        patientCode: doc.patientCode,
        finishedAt: doc.finishedAt)


# piece together
dumpList = (head, req) ->
  _ = require('views/lib/underscore')._

  keyType = _.last(req.path)

  if not (req.path.length is 6 and keyType in ['encounter', 'patient', 'task'])
    throw new Error('You may only dump the encounter, patient, or task view')

  start(headers:
    'Content-Type': 'application/json')

  send('[\n')

  currentKey = null
  keyDoc = null
  taskToEventLog = {}
  encounterToTasks = {}
  encounters = []

  # add encounterNum to each encounter in patient.encounters, and sort
  fixPatientEncounters = (patient) ->
    if patient.encounters?
      if patient.encounterIds?
        encounterToNum = _.object([id, i] for id, i in patient.encounterIds)
        for encounter in patient.encounters
          encounter.encounterNum = encounterToNum[encounter._id]

      # sort by encounter start if we have it, otherwise go with encounterNum
      patient.encounters = _.sortBy(
        patient.encounters, (e) -> [e.limitedPHI?.clockOffset, e.encounterNum])

  sendDoc = (doc) ->
    if doc.type is 'patient'
      fixPatientEncounters(doc)

    send(JSON.stringify(keyDoc, null, 2))

  while row = getRow()
    if keyType is 'patient'
      [key, encounterId, startedAt, docType] = row.key
    else
      [key, startedAt, docType] = row.key
      encounterId = null

    # skip docs created with no encounter ID
    if not key?
      continue

    # reconstruct the document
    doc = _.extend({type: docType}, row.value, {_id: row.id}, row.doc)
    if keyType is 'patient'
      doc.patientCode ?= key
      if encounterId? and doc.type isnt 'encounter'
        doc.encounterId ?= encounterId

    if doc.type is 'task'
      doc.startedAt = startedAt
      # fix for old format where trialNum was 1-indexed
      if doc.eventLog? and doc.version in ['0.1.0', '0.2.0']
        for item in doc.eventLog
          if item.state?.trialNum?
            item.state.trialNum -= 1

    # when we encounter a new key, dump the last document we constructed
    if key isnt currentKey
      if keyDoc?
        sendDoc(keyDoc)
        send(',\n')
      keyDoc =
        _id: if keyType is 'patient' then 'patient-' + key else key
        type: keyType
      currentKey = key
      taskToEventLog = {}
      encounterToTasks = {}
      encounters = []

    # link documents together
    switch doc.type
      when 'encounter'
        # make sure doc.tasks and encounterToTasks[doc._id] are the same list
        tasks = doc.tasks ? encounterToTasks[doc._id] ? []
        doc.tasks ?= tasks
        encounterToTasks[doc._id] ?= tasks

        # add to encounters
        if keyType is 'patient'
          encounters.push(doc)

      when 'eventLog'
        # don't create eventLog if there's no way to construct it
        if req.query.include_docs
          taskId = doc.taskId ? if keyType is 'task' then key
          if taskId?
            eventLog = (taskToEventLog[taskId] ?= [])
            if doc.items?
              for item, i in doc.items
                eventLog[i + doc.startIndex] = item

      when 'patient'
        switch keyType
          when 'encounter'
            if doc.encounterNum?
              keyDoc.encounterNum = doc.encounterNum
          when 'patient'
            doc.encounters ?= encounters

      when 'task'
        # don't create eventLog if there's no way to construct it
        if req.query.include_docs
          eventLog = doc.eventLog ? taskToEventLog[doc._id] ? []
          doc.eventLog ?= eventLog
          taskToEventLog[doc._id] ?= eventLog

        # add to encounterToTasks
        if keyType isnt 'task'
          encounterId = doc.encounterId ? if keyType is 'encounter' then key
          if encounterId?
            (encounterToTasks[encounterId] ?= []).push(doc)

    # if this the key document, dump all its fields into keyDoc
    if doc.type is keyType
      _.extend(keyDoc, doc)


  # dump last key document
  if keyDoc?
    sendDoc(keyDoc)
    send('\n')  # no comma, since this is the last one

  send(']\n')


exports.lists =
  dump: dumpList


exports.views =
  encounter:
    map: encounterMap
  patient:
    map: patientMap
  task:
    map: taskMap
