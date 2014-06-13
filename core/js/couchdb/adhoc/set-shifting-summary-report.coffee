
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
  'shiftScore',
  'shiftErrorDiff',
  'colorCorr',
  'colorErrors',
  'colorMean',
  'colorMedian',
  'colorStdev',
  'shapeCorr',
  'shapeErrors',
  'shapeMean',
  'shapeMedian',
  'shapeStdev',
  'shiftCorr',
  'shiftErrors',
  'shiftMean',
  'shiftMedian',
  'shiftStdev',
  'shiftedCorr',
  'shiftedErrors',
  'shiftedMean',
  'shiftedMedian',
  'shiftedStdev',
  'nonshiftedCorr',
  'nonshiftedErrors',
  'nonshiftedMean',
  'nonshiftedMedian',
  'nonshiftedStdev',
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
shiftScore =
shiftErrorDiff =
colorCorr =
colorErrors =
colorMean =
colorMedian =
colorStdev =
shapeCorr =
shapeErrors =
shapeMean =
shapeMedian =
shapeStdev =
shiftCorr =
shiftErrors =
shiftMean =
shiftMedian =
shiftStdev =
shiftedCorr =
shiftedErrors =
shiftedMean =
shiftedMedian =
shiftedStdev =
nonshiftedCorr =
nonshiftedErrors =
nonshiftedMean =
nonshiftedMedian =
nonshiftedStdev = null

# helper variables
color =
shape =
shift =
shifted =
nonshifted = null

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
  colorErrors =
  shapeErrors =
  shiftErrors =
  shiftedErrors =
  nonshiftedErrors = 0
    
  shiftScore =
  shiftErrorDiff =
  colorCorr =
  colorMean =
  colorMedian =
  colorStdev =
  shapeCorr =
  shapeMean =
  shapeMedian =
  shapeStdev =
  shiftCorr =
  shiftMean =
  shiftMedian =
  shiftStdev =
  shiftedCorr =
  shiftedMean =
  shiftedMedian =
  shiftedStdev =
  nonshiftedCorr =
  nonshiftedMean =
  nonshiftedMedian =
  nonshiftedStdev = examiner.ERROR_CANNOT_CALCULATE
  
  color = []
  shape = []
  shift = []
  shifted = []
  nonshifted = []

calculateSummaryScores = ->
  colorVec = new gauss.Vector(color)
  colorCorr = color.length
  colorMean = colorVec.mean()
  colorMedian = colorVec.median()
  colorStdev = colorVec.stdev()

  shapeVec = new gauss.Vector(shape)
  shapeCorr = shape.length
  shapeMean = shapeVec.mean()
  shapeMedian = shapeVec.median()
  shapeStdev = shapeVec.stdev()

  shiftVec = new gauss.Vector(shift)
  shiftCorr = shift.length
  shiftMean = shiftVec.mean()
  shiftMedian = shiftVec.median()
  shiftStdev = shiftVec.stdev()

  shiftedVec = new gauss.Vector(shifted)
  shiftedCorr = shifted.length
  shiftedMean = shiftedVec.mean()
  shiftedMedian = shiftedVec.median()
  shiftedStdev = shiftedVec.stdev()

  nonshiftedVec = new gauss.Vector(nonshifted)
  nonshiftedCorr = nonshifted.length
  nonshiftedMean = nonshiftedVec.mean()
  nonshiftedMedian = nonshiftedVec.median()
  nonshiftedStdev = nonshiftedVec.stdev()

  calcShiftScore()
  calcShiftErrorDiff()

# helper to calculate log 10 values
log10 = (val) ->
  Math.log(val) / Math.LN10

# calculate shift score
calcShiftScore = ->
  if totalTrials isnt 104 or
  shiftCorr is examiner.ERROR_CANNOT_CALCULATE or
  shiftMedian is examiner.ERROR_CANNOT_CALCULATE or
  shiftErrors is examiner.ERROR_CANNOT_CALCULATE
    return
  
  accuracyScore = shiftCorr / (shiftCorr + shiftErrors) * 5
  
  # set performance floor and ceiling
  if shiftMedian < 0.4
    shiftMedian = 0.4
  if shiftMedian > 2.8
    shiftMedian = 2.8

  log0_4 = log10(0.4)
  shiftMedianAdjusted = (log10(shiftMedian) - log0_4) / (log10(2.8) - log0_4)
  reactionTimeScore = 5 - (5 * shiftMedianAdjusted)
  
  shiftScore = (accuracyScore + reactionTimeScore).toFixed(3)

# calculate difference in errors from shift condition
# to the color and shape conditions
calcShiftErrorDiff = ->
  if totalTrials isnt 104 or
  shiftErrors is examiner.ERROR_CANNOT_CALCULATE or
  colorErrors is examiner.ERROR_CANNOT_CALCULATE or
  shapeErrors is examiner.ERROR_CANNOT_CALCULATE
    return

  shiftErrorDiff = shiftErrors - (colorErrors + shapeErrors)

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
    
    # handle color block
    trialCondition = item.state.stimuli.condition
    respCorr = item.interpretation.correct
    respRt = item.interpretation.responseTime / TIME_CONVERTER
    
    if trialCondition is 'color'
      if respCorr
        color.push(respRt)
      else
        colorErrors += 1
    else if trialCondition is 'shape'
      if respCorr
        shape.push(respRt)
      else
        shapeErrors += 1
    else if trialCondition is 'shift'
      if item.state.stimuli.shift # if a shifted trial
        if respCorr
          shift.push(respRt)
          shifted.push(respRt)
        else
          shiftErrors += 1
          shiftedErrors += 1
      else # nonshifted trials
        if respCorr
          shift.push(respRt)
          nonshifted.push(respRt)
        else
          shiftErrors += 1
          nonshiftedErrors += 1
        
patientHandler = (patientRecord) ->
  examiner.setshiftingPatientTraverser(patientRecord, itemHandler)

exports.list = (head, req) ->
  keyType = req.path[req.path.length - 1]

  if not (req.path.length is 6 and keyType is 'patient')
    throw new Error('You may only dump the patient view')

  isoDate = (new Date()).toISOString()[..9]

  start(headers:
    'Content-Disposition': (
      "attachment; filename=\"set-shifting-summary-report-#{isoDate}.csv"),
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
    shiftScore,
    shiftErrorDiff,
    colorCorr,
    colorErrors,
    colorMean,
    colorMedian,
    colorStdev,
    shapeCorr,
    shapeErrors,
    shapeMean,
    shapeMedian,
    shapeStdev,
    shiftCorr,
    shiftErrors,
    shiftMean,
    shiftMedian,
    shiftStdev,
    shiftedCorr,
    shiftedErrors,
    shiftedMean,
    shiftedMedian,
    shiftedStdev,
    nonshiftedCorr,
    nonshiftedErrors,
    nonshiftedMean,
    nonshiftedMedian,
    nonshiftedStdev
  ]
  
  if taskId
    send(csv.arrayToCsv([results]))