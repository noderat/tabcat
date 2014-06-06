
cptPatientTraverser = (patientRecord, itemHandler) ->
  patientCode = patientRecord.patientCode
  for encounter in patientRecord.encounters
    for task in encounter.tasks
      if task.name is 'cpt' and task.eventLog? and task.finishedAt?
        for item in task.eventLog
          if item?.interpretation? and item?.state?
            itemHandler(patientRecord, encounter, task, item)
        # only keep the first task per patient
        return

flankerPatientTraverser = (patientRecord, itemHandler) ->
  patientCode = patientRecord.patientCode
  for encounter in patientRecord.encounters
    for task in encounter.tasks
      if task.name is 'flanker' and task.eventLog? and task.finishedAt?
        for item in task.eventLog
          if item?.state?.stimuli?
            itemHandler(patientRecord, encounter, task, item)
        # only keep the first task per patient
        return

setshiftingPatientTraverser = (patientRecord, itemHandler) ->
  patientCode = patientRecord.patientCode
  for encounter in patientRecord.encounters
    for task in encounter.tasks
      if task.name is 'setshifting' and task.eventLog? and task.finishedAt?
        for item in task.eventLog
          if item?.interpretation? and item?.state?
            itemHandler(patientRecord, encounter, task, item)
        # only keep the first task per patient
        return

exports.ERROR_CANNOT_CALCULATE = -5
exports.cptPatientTraverser = cptPatientTraverser
exports.flankerPatientTraverser = flankerPatientTraverser
exports.setshiftingPatientTraverser = setshiftingPatientTraverser