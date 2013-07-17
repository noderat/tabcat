encounterMap = (doc) ->
  if doc.type is 'encounter'
    emit([doc._id, 'encounter'],
      _id: doc._id,  # just for consistency
      patientCode: doc.patientCode,
      clockOffset: doc.limitedPHI?.clockOffset)
  else if doc.type is 'task'
    emit([doc.encounterId, 'task', doc.startedAt],
      _id: doc._id,
      name: doc.name,
      finishedAt: doc.finishedAt)
  else if doc.type is 'patient'
    if doc.encounterIds?
      for encounterId, i in doc.encounterIds
        emit([encounterId, 'patient'],
          _id: doc._id,
          encounterNum: i + 1,
          patientCode: doc.patientCode)


exports.views =
  encounter:
    map: encounterMap
