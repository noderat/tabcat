
_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')
examiner = require('./examiner')
gauss = require('js/vendor/gauss/gauss')

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
  'totalTrials',
  'flankerScore',
  'flankerErrorDiff',
  'totalCorr',
  'totalMean',
  'totalMedian',
  'totalStdev',
  'congrCorr',
  'congrMean',
  'congrMedian',
  'congrStdev',
  'incongrCorr',
  'incongrMean',
  'incongrMedian',
  'incongrStdev',
  'leftCorr',
  'leftMean',
  'leftMedian',
  'leftStdev',
  'rightCorr',
  'rightMean',
  'rightMedian',
  'rightStdev',
  'upCorr',
  'upMean',
  'upMedian',
  'upStdev',
  'downCorr',
  'downMean',
  'downMedian',
  'downStdev'
]

# convert ms to seconds
TIME_CONVERTER = 1000

# declare all variables used in calculations
taskId =
taskName =
taskVersion =
taskLanguage =
patientCode =
encounterNum =
encounterYear =
taskStart =
taskFinish =
totalTrials =
flankerScore =
flankerErrorDiff =
totalCorr =
totalMean =
totalMedian =
totalStdev =
congrCorr =
congrMean =
congrMedian =
congrStdev =
incongrCorr =
incongrMean =
incongrMedian =
incongrStdev =
leftCorr =
leftMean =
leftMedian =
leftStdev =
rightCorr =
rightMean =
rightMedian =
rightStdev =
upCorr =
upMean =
upMedian =
upStdev =
downCorr =
downMean =
downMedian =
downStdev = null

# helper variables
total =
congr =
incongr =
left =
right =
up =
down = null

initializeSummaryScores = ->
  taskId =
  taskName =
  taskVersion =
  taskLanguage =
  patientCode =
  encounterNum =
  encounterYear =
  taskStart =
  taskFinish = null
  
  totalTrials =
  totalCorr =
  congrCorr =
  incongrCorr =
  leftCorr =
  rightCorr =
  upCorr =
  downCorr = 0

  flankerScore =
  flankerErrorDiff =
  totalMean =
  totalMedian =
  totalStdev =
  congrMean =
  congrMedian =
  congrStdev =
  incongrMean =
  incongrMedian =
  incongrStdev =
  leftMean =
  leftMedian =
  leftStdev =
  rightMean =
  rightMedian =
  rightStdev =
  upMean =
  upMedian =
  upStdev =
  downMean =
  downMedian =
  downStdev = examiner.ERROR_CANNOT_CALCULATE
  
  total = []
  congr = []
  incongr = []
  left = []
  right = []
  up = []
  down = []

calculateSummaryScores = ->
  totalVec = new gauss.Vector(total)
  totalCorr = total.length
  totalMean = totalVec.mean()
  totalMedian = totalVec.median()
  totalStdev = totalVec.stdev()

  congrVec = new gauss.Vector(congr)
  congrCorr = congr.length
  congrMean = congrVec.mean()
  congrMedian = congrVec.median()
  congrStdev = congrVec.stdev()

  incongrVec = new gauss.Vector(incongr)
  incongrCorr = incongr.length
  incongrMean = incongrVec.mean()
  incongrMedian = incongrVec.median()
  incongrStdev = incongrVec.stdev()

  leftVec = new gauss.Vector(left)
  leftCorr = left.length
  leftMean = leftVec.mean()
  leftMedian = leftVec.median()
  leftStdev = leftVec.stdev()

  rightVec = new gauss.Vector(right)
  rightCorr = right.length
  rightMean = rightVec.mean()
  rightMedian = rightVec.median()
  rightStdev = rightVec.stdev()

  upVec = new gauss.Vector(up)
  upCorr = up.length
  upMean = upVec.mean()
  upMedian = upVec.median()
  upStdev = upVec.stdev()

  downVec = new gauss.Vector(down)
  downCorr = down.length
  downMean = downVec.mean()
  downMedian = downVec.median()
  downStdev = downVec.stdev()

  calcFlankerScore()
  calcErrorDiff()

# helper to calculate log 10 values
log10 = (val) ->
  Math.log(val) / Math.LN10

# calculate flanker score
calcFlankerScore = ->
  if totalTrials isnt 48 or
  incongrCorr is examiner.ERROR_CANNOT_CALCULATE or
  incongrMedian is examiner.ERROR_CANNOT_CALCULATE
    return
      
  accuracyScore = incongrCorr / 24 * 5
  
  # set performance floor and ceiling
  if incongrMedian < 0.5
    incongrMedian = 0.5
  if incongrMedian > 3
    incongrMedian = 3
  
  log0_5 = log10(0.5)
  incongrMedianAdjusted = (log10(incongrMedian)-log0_5)/(log10(3)-log0_5)
  reactionTimeScore = 5 - (5 * incongrMedianAdjusted)

  flankerScore = (accuracyScore + reactionTimeScore).toFixed(3)

# calculate difference in errors from incongruent to congruent conditions
calcErrorDiff = ->
  if totalTrials isnt 48 or
  incongrCorr is examiner.ERROR_CANNOT_CALCULATE or
  incongrMedian is examiner.ERROR_CANNOT_CALCULATE
    return

  flankerErrorDiff = (24 - incongrCorr) - (24 - congrCorr)

itemHandler = (patientRecord, encounter, task, item) ->
  if item.state.trialBlock is 'testingBlock'
    # these values only need to be determined once
    if not taskName?
      taskId = task._id
      taskName = task.name
      taskVersion = task.version
      taskLanguage = task.language
      patientCode = patientRecord.patientCode
      encounterNum = encounter.encounterNum
      encounterYear = encounter.year
      taskStart = task.startedAt / TIME_CONVERTER
      taskFinish = task.finishedAt / TIME_CONVERTER
      
    totalTrials += 1
    rt = item.interpretation?.responseTime / TIME_CONVERTER
    if item.interpretation?.correct
      total.push(rt)
      if item.state.stimuli.congruent
        congr.push(rt)
      else
        incongr.push(rt)
      if item.state.stimuli.arrows.charAt(2) is 'l'
        left.push(rt)
      else
        right.push(rt)
      if item.state.stimuli.upDown is 'up'
        up.push(rt)
      else
        down.push(rt)
        
patientHandler = (patientRecord) ->
  examiner.flankerPatientTraverser(patientRecord, itemHandler)

exports.list = (head, req) ->
  keyType = req.path[req.path.length - 1]

  if not (req.path.length is 6 and keyType is 'patient')
    throw new Error('You may only dump the patient view')

  isoDate = (new Date()).toISOString()[..9]

  start(headers:
    'Content-Disposition': (
      "attachment; filename=\"flanker-summary-report-#{isoDate}.csv"),
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
    taskLanguage,
    patientCode,
    encounterNum,
    encounterYear,
    taskStart,
    taskFinish,
    totalTrials,
    flankerScore,
    flankerErrorDiff,
    totalCorr,
    totalMean,
    totalMedian,
    totalStdev,
    congrCorr,
    congrMean,
    congrMedian,
    congrStdev,
    incongrCorr,
    incongrMean,
    incongrMedian,
    incongrStdev,
    leftCorr,
    leftMean,
    leftMedian,
    leftStdev,
    rightCorr,
    rightMean,
    rightMedian,
    rightStdev,
    upCorr,
    upMean,
    upMedian,
    upStdev,
    downCorr,
    downMean,
    downMedian,
    downStdev
  ]
  
  if taskId
    send(csv.arrayToCsv([results]))