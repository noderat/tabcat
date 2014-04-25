
_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')

patientHandler = (patientRecord) ->
  patientCode = patientRecord.patientCode

  for encounter in patientRecord.encounters
    for task in encounter.tasks
      if task.name is 'flanker' and task.eventLog? and task.finishedAt?
        version = task.version ? null
        subject_id = patientCode
        encounter_num = encounter.encounterNum
        block_name = null
        trial_congruent = null
        trial_arrows = null
        trial_upDown = null
        trial_corrResp = null
        trial_fixation = null
        resp_value = null
        resp_corr = null
        resp_rt = null
        task_time = null

        for item in task.eventLog
          if item?.state?.trial?
            block_name = item.state.block
            trial_congruent = item.state.trial.congruent
            trial_arrows = item.state.trial.arrows
            trial_upDown = item.state.trial.upDown
            trial_corrResp = item.state.trial.corrAns
            trial_fixation = item.state.fixationDuration
            resp_value = item.state.response
            resp_corr = if item.interpretation.correct then 1 else 0
            resp_rt = item.state.responseTime
            task_time = item.now / 1000

            data = [
              version,
              subject_id,
              encounter_num,
              block_name,
              trial_congruent,
              trial_arrows,
              trial_upDown,
              trial_corrResp,
              trial_fixation,
              resp_value,
              resp_corr,
              resp_rt,
              task_time
            ]

            send(csv.arrayToCsv([data]))

  # only keep the first task per patient
  return

exports.list = (head, req) ->
  keyType = req.path[req.path.length - 1]

  if not (req.path.length is 6 and keyType is 'patient')
    throw new Error('You may only dump the patient view')

  isoDate = (new Date()).toISOString()[..9]

  start(headers:
    'Content-Disposition': (
      "attachment; filename=\"flanker-report-#{isoDate}.csv"),
    'Content-Type': 'text/csv')

  csvHeader = [
    'version',
    'subject_id',
    'encounter_num',
    'block_name',
    'trial_congruent',
    'trial_arrows',
    'trial_upDown',
    'trial_corrResp',
    'trial_fixation',
    'resp_value',
    'resp_corr',
    'resp_rt',
    'task_time'
  ]

  send(csv.arrayToCsv([csvHeader]))

  patient.iterate(getRow, patientHandler)