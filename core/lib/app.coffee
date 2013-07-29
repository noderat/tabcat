# group docs by encounter ID, and order chronologically
#
# key is [encounterId, encounterClockTime, docType]
#
# encounterNum is with the patient doc (since that contains the list
# of encounter IDs)
encounterMap = (doc) ->
  if doc.type is 'encounter'
    emit([doc._id, 0, 'encounter'],
      _id: doc._id,  # just for consistency
      patientCode: doc.patientCode,
      clockOffset: doc.limitedPHI?.clockOffset)
  else if doc.type is 'eventLog'
    emit([doc.encounterId, doc.items[0].now, 'eventLog'],
      _id: doc._id,
      startIndex: doc.startIndex,
      endIndex: doc.startIndex + doc.items.length)
  else if doc.type is 'task'
    emit([doc.encounterId, doc.startedAt, 'task'],
      _id: doc._id,
      name: doc.name,
      finishedAt: doc.finishedAt)
  else if doc.type is 'patient'
    if doc.encounterIds?
      for encounterId, i in doc.encounterIds
        emit([encounterId, null, 'patient'],
          _id: doc._id,
          encounterNum: i + 1,
          patientCode: doc.patientCode)


# group docs by task ID, and order chronologically
taskMap = (doc) ->
  if doc.type is 'eventLog'
    emit([doc.taskId, doc.items[0].now, 'eventLog'],
      _id: doc._id,
      startIndex: doc.startIndex,
      endIndex: doc.startIndex + doc.items.length)
  else if doc.type is 'task'
    emit([doc._id, doc.startedAt, 'task'],
      _id: doc._id,
      name: doc.name,
      patientCode: doc.patientCode,
      finishedAt: doc.finishedAt)


exports.views =
  encounter:
    map: encounterMap
  task:
    map: taskMap
