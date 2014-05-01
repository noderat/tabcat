
_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')

CSV_HEADER = [
  'version',
  'patientCode',
  'encounterNum',
  'triaBlock',
  'trialNum',
  'trialCongruent',
  'trialArrows',
  'trialUpDown',
  'trialCorrResp',
  'trialFixation',
  'respValue',
  'respCorr',
  'respRt',
  'taskTime'
]

patientHandler = (patientRecord) ->
  patientCode = patientRecord.patientCode

  for encounter in patientRecord.encounters
    for task in encounter.tasks
      if task.name is 'flanker' and task.eventLog? and task.finishedAt?

        for item in task.eventLog
          if item?.state?.stimuli?
            data = [
              task.version,
              patientCode,
              encounter.encounterNum,
              item.state.trialBlock,
              item.state.trialNum,
              item.state.stimuli.congruent,
              item.state.stimuli.arrows,
              item.state.stimuli.upDown,
              item.state.stimuli.arrows.charAt(2),
              item.state.stimuli.fixationDuration,
              item.interpretation.response,
              item.interpretation.correct,
              item.interpretation.responseTime,
              item.now / 1000
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



  send(csv.arrayToCsv([CSV_HEADER]))

  patient.iterate(getRow, patientHandler)