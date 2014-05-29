
_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')

CSV_HEADER = [
  'taskName',
  'taskVersion',
  'taskLanguage',
  'patientCode',
  'encounterNum',
  'encounterYear',
  'taskStart',
  'taskFinish',
  'trialBlock',
  'trialNum',
  'trialCondition',
  'trialCue',
  'trialCorrResp',
  'trialShift',
  'respValue',
  'respCorr',
  'respRt',
  'taskTime'
]

# convert ms to seconds
TIME_CONVERTER = 1000

patientHandler = (patientRecord) ->
  patientCode = patientRecord.patientCode
  for encounter in patientRecord.encounters
    for task in encounter.tasks
      if task.name is 'setshifting' and task.eventLog? and task.finishedAt?
        for item in task.eventLog
          if item?.interpretation? and item?.state?
            data = [
              task.name,
              task.version,
              task.language,
              patientCode,
              encounter.encounterNum,
              encounter.year,
              task.startedAt / TIME_CONVERTER,
              task.finishedAt / TIME_CONVERTER,
              item.state.trialBlock,
              item.state.trialNum,
              item.state.stimuli.condition,
              item.state.stimuli.cue,
              item.state.stimuli.corrResp,
              item.state.stimuli.shift,
              item.interpretation.response?.respValue ? "none",
              if item.interpretation.correct then "1" else "0",
              item.interpretation.responseTime / TIME_CONVERTER,
              item.now / TIME_CONVERTER
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
      "attachment; filename=\"set-shifting-detail-report-#{isoDate}.csv"),
    'Content-Type': 'text/csv')

  send(csv.arrayToCsv([CSV_HEADER]))

  patient.iterate(getRow, patientHandler)