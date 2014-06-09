
_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')
examiner = require('./examiner')
gauss = require('js/vendor/gauss/gauss')

CSV_HEADER = [
  'taskId',
  'taskName',
  'taskVersion',
  'taskForm',
  'taskLanguage',
  'patientCode',
  'encounterNum',
  'encounterYear',
  'taskStart',
  'taskFinish',
  'totalTrials',
  'totalCorr',
  'totalErrors',
  'targetCorr',
  'targetErrors',
  'targetMean',
  'targetMedian',
  'targetStdev',
  'nontargetCorr',
  'nontargetErrors',
  'performanceErrors'
]

# convert ms to seconds
TIME_CONVERTER = 1000

# declare all variables used in calculations
taskId =
taskName =
taskVersion =
taskForm =
taskLanguage =
patientCode =
encounterNum =
encounterYear =
taskStart =
taskFinish =
totalTrials =
totalCorr =
totalErrors =
targetCorr =
targetErrors =
nontargetCorr =
nontargetErrors =
performanceErrors =
targetMean =
targetMedian =
targetStdev = null

# helper variable used for targetMean, targetMedian, targetStdev
target = null

initializeSummaryScores = ->
  taskId =
  taskName =
  taskVersion =
  taskForm =
  taskLanguage =
  patientCode =
  encounterNum =
  encounterYear =
  taskStart =
  taskFinish = null
  
  totalTrials =
  totalCorr =
  totalErrors =
  targetCorr =
  targetErrors =
  nontargetCorr =
  nontargetErrors =
  performanceErrors = 0
  
  targetMean =
  targetMedian =
  targetStdev = examiner.ERROR_CANNOT_CALCULATE
  
  target = []
  
calculateSummaryScores = ->
  nums = new gauss.Vector(target)
  targetMean = nums.mean()
  targetMedian = nums.median()
  targetStdev = nums.stdev()

itemHandler = (patientRecord, encounter, task, item) ->
  if item.state.trialBlock is 'testingBlock'
    # these values only need to be determined once
    if not taskName?
      taskId = task._id
      taskName = task.name
      taskVersion = task.version
      taskForm = item.state.version
      taskLanguage = task.language
      patientCode = patientRecord.patientCode
      encounterNum = encounter.encounterNum
      encounterYear = encounter.year
      taskStart = task.startedAt / TIME_CONVERTER
      taskFinish = task.finishedAt / TIME_CONVERTER
      
    totalTrials += 1
    
    # handle correct trials
    if item.interpretation.correct
      totalCorr += 1
      if item.state.stimuli.stimulus is 'target'
        targetCorr += 1
        target.push(item.interpretation.responseTime)
      else
        nontargetCorr += 1

    # handle incorrect trials
    else
      totalErrors += 1
      if item.interpretation.extraResponses is 'none'
        if item.state.stimuli.stimulus is 'target'
          targetErrors += 1
        else
          nontargetErrors += 1
      else
        performanceErrors += 1

patientHandler = (patientRecord) ->
  examiner.cptPatientTraverser(patientRecord, itemHandler)

exports.list = (head, req) ->
  keyType = req.path[req.path.length - 1]

  if not (req.path.length is 6 and keyType is 'patient')
    throw new Error('You may only dump the patient view')

  isoDate = (new Date()).toISOString()[..9]

  start(headers:
    'Content-Disposition': (
      "attachment; filename=\"cpt-summary-report-#{isoDate}.csv"),
    'Content-Type': 'text/csv')

  send(csv.arrayToCsv([CSV_HEADER]))

  # required because looks like values are cached between report executions
  initializeSummaryScores()

  patient.iterate(getRow, patientHandler)
  
  calculateSummaryScores()
  
  results = [
    taskId,
    taskName,
    taskVersion,
    taskForm,
    taskLanguage,
    patientCode,
    encounterNum,
    encounterYear,
    taskStart,
    taskFinish,
    totalTrials,
    totalCorr,
    totalErrors,
    targetCorr,
    targetErrors,
    targetMean,
    targetMedian,
    targetStdev,
    nontargetCorr,
    nontargetErrors,
    performanceErrors
  ]
  
  if taskId
    send(csv.arrayToCsv([results]))