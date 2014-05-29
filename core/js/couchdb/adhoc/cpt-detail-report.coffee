
_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')

CSV_HEADER = [
  'taskName',
  'taskVersion',
  'taskForm',
  'taskLanguage',
  'patientCode',
  'encounterNum',
  'encounterYear',
  'taskStart',
  'taskFinish',
  'trialBlock',
  'trialNum',
  'trialStimulus',
  'trialExtraResponses',
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
      if task.name is 'cpt' and task.eventLog? and task.finishedAt?
        for item in task.eventLog
          if item?.interpretation? and item?.state?
            data = [
              task.name,
              task.version,
              item.state.version,
              task.language,
              patientCode,
              encounter.encounterNum,
              encounter.year,
              task.startedAt / TIME_CONVERTER,
              task.finishedAt / TIME_CONVERTER,
              item.state.trialBlock,
              item.state.trialNum,
              item.state.stimuli.stimulus,
              item.interpretation.extraResponses,
              item.event?.type ? 'none',
              if item.interpretation.correct then '1' else '0',
              item.interpretation.responseTime,
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
      "attachment; filename=\"cpt-detail-report-#{isoDate}.csv"),
    'Content-Type': 'text/csv')

  send(csv.arrayToCsv([CSV_HEADER]))

  patient.iterate(getRow, patientHandler)