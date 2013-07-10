_ = require('underscore')

encounterMap = (doc) ->
  if doc.type is 'encounter'
    emit([doc._id], _.pick(doc, '_id', 'type', 'patientCode'))
  else if doc.type is 'task'
    if doc.encounterId? and doc.startedAt?
      emit(
        [doc.encounterId, doc.startedAt],
        _.pick(doc, '_id', 'type', 'name', 'finishedAt'))

exports.views =
  encounter:
    map: encounterMap
