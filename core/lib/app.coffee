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

  if not (req.path.length is 6 and keyType in ['encounter', 'task'])
    throw new Error('You may only dump the encounter or task view')

  start(headers:
    'Content-Type': 'application/json')

  send('[\n')

  keyDoc = null
  taskToEventLog = {}
  encounterToTasks = {}

  while row = getRow()
    [keyId, startedAt, docType] = row.key

    # skip docs created with no encounter ID
    if not keyId?
      continue

    # reconstruct the document
    doc = _.extend({type: docType}, row.value, {_id: row.id}, row.doc)
    if doc.type is 'task'
      doc.startedAt = startedAt
      # fix for old format where trialNum was 1-indexed
      if doc.eventLog? and doc.version in ['0.1.0', '0.2.0']
        for item in doc.eventLog
          if item.state?.trialNum?
            item.state.trialNum -= 1

    # when we encounter a new keyId, dump the last document we constructed
    if keyDoc?._id isnt keyId
      if keyDoc?
        send(JSON.stringify(keyDoc, null, 2))
        send(',\n')
      keyDoc =
        _id: keyId
        type: keyType
      taskToEventLog = {}
      encounterToTasks = {}

    # link documents together
    switch doc.type
      when 'encounter'
        # make sure doc.tasks and encounterToTasks[doc._id] are the same list
        tasks = doc.tasks ? encounterToTasks[doc._id] ? []
        doc.tasks ?= tasks
        encounterToTasks[doc._id] ?= tasks

      when 'eventLog'
        # don't create eventLog if there's no way to construct it
        if req.query.include_docs
          taskId = doc.taskId ? if keyType is 'task' then keyId
          if taskId?
            eventLog = (taskToEventLog[taskId] ?= [])
            if doc.items?
              for item, i in doc.items
                eventLog[i + doc.startIndex] = item

      when 'patient'
        # right now we don't want this doc, patient code is enough

        # the encounter view figures out encounterNum from patient.encounterIds
        if doc.encounterNum? and keyType is 'encounter'
          keyDoc.encounterNum = doc.encounterNum

      when 'task'
        # don't create eventLog if there's no way to construct it
        if req.query.include_docs
          eventLog = doc.eventLog ? taskToEventLog[doc._id] ? []
          doc.eventLog ?= eventLog
          taskToEventLog[doc._id] ?= eventLog

        if keyType isnt 'task'
          encounterId = doc.encounterId ? if keyType is 'encounter' then keyId
          if encounterId?
            (encounterToTasks[encounterId] ?= []).push(doc)

    # if this the key document, dump all its fields into keyDoc
    if doc._id is keyDoc._id and doc.type is keyDoc.type
      _.extend(keyDoc, doc)


  # dump last key document
  if keyDoc?
    send(JSON.stringify(keyDoc, null, 2))
    send('\n')  # no comma, since this is the last one

  send(']\n')


exports.lists =
  dump: dumpList


exports.views =
  encounter:
    map: encounterMap
  task:
    map: taskMap
