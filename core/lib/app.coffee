encounterMap = (doc) ->
  if doc.type is 'encounter'

    value =
      _id: doc._id
      type: doc.type
    if doc.patientCode?
      value.patientCode = doc.patientCode

    emit([doc._id], value)

  else if doc.type is 'task'
    if doc.encounterId? and doc.startedAt?

      value =
        _id: doc._id
        type: doc.type

      if doc.name?
        value.name = doc.name

      if doc.finishedAt?
        value.finishedAt = doc.finishedAt

      emit([doc.encounterId, doc.startedAt], value)


exports.views =
  encounter:
    map: encounterMap
