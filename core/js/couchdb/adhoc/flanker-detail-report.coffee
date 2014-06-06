
_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')
examiner = require('./examiner')

CSV_HEADER = [
  'taskId',
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

# convert ms to seconds
TIME_CONVERTER = 1000

itemHandler = (patientRecord, encounter, task, item) ->
  data = [
    task._id,
    task.name,
    task.version,
    task.language,
    patientRecord.patientCode,
    encounter.encounterNum,
    encounter.year,
    task.startedAt / TIME_CONVERTER,
    task.finishedAt / TIME_CONVERTER,
    item.state.trialBlock,
    item.state.trialNum,
    if item.state.stimuli.congruent then "1" else "0",
    item.state.stimuli.arrows,
    item.state.stimuli.upDown,
    item.state.stimuli.arrows.charAt(2),
    item.state.stimuli.fixationDuration / TIME_CONVERTER,
    item.interpretation.response,
    if item.interpretation.correct then "1" else "0",
    item.interpretation.responseTime / TIME_CONVERTER,
    item.now / TIME_CONVERTER
  ]
  
  send(csv.arrayToCsv([data]))

patientHandler = (patientRecord) ->
  examiner.flankerPatientTraverser(patientRecord, itemHandler)

exports.list = (head, req) ->
  keyType = req.path[req.path.length - 1]

  if not (req.path.length is 6 and keyType is 'patient')
    throw new Error('You may only dump the patient view')

  isoDate = (new Date()).toISOString()[..9]

  start(headers:
    'Content-Disposition': (
      "attachment; filename=\"flanker-detail-report-#{isoDate}.csv"),
    'Content-Type': 'text/csv')

  send(csv.arrayToCsv([CSV_HEADER]))

  patient.iterate(getRow, patientHandler)