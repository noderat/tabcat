###
Copyright (c) 2013-2015, Regents of the University of California
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

_ = require('js/vendor/underscore')._
csv = require('js/vendor/ucsv')
patient = require('../patient')
report = require('./report')

#the reporting columns will be based on correct answers
#and errors in every 15 second interval
REPORTING_INTERVAL = 15

SECONDS_IN_TRIAL = 120

MAX_INTERVALS = SECONDS_IN_TRIAL / REPORTING_INTERVAL

makeHeaders = (prefix) ->
  prefix + (i - 1) * REPORTING_INTERVAL + 'to' + i * REPORTING_INTERVAL \
    for i in [1..MAX_INTERVALS]

columns = [
  'subject_id',
  'session_date',
  'sesion_start',
  'machine',
  'Form',
].concat(
  makeHeaders('corr_')
).concat(
  makeHeaders('errors_')
)

patientHandler = (patientRecord) ->
  patientCode = patientRecord.patientCode

  taskInfo = {}
  for encounter in patientRecord.encounters
    for task in encounter.tasks
      if task.finishedAt and task.eventLog?
        # only keep the first task per patient
        if taskInfo
          continue

        # this isn't an off-by one; we discard the first trial because we
        # don't know when the patient first gets the task
        # using ? null because _.max() handles undefined differently
        numTrials = _.max(
          item?.state?.trialNum ? null for item in task.eventLog)

        firstAction = _.find(task.eventLog, (item) -> item?.interpretation?)
        totalTime = (task.finishedAt - firstAction.now) / 1000

        taskInfo = [
          report.getVersion(task),
          report.getDate(task),
        ].concat(report.getDataQualityCols(encounter)).concat([
          totalTime,
          task.eventLog
        ]).concat(intensitiesAtReversal).concat(
          catchTrials
        )

  if _.isEmpty(taskInfo)
    return

  data = []


  data[0] = patientCode
  if taskInfo?
    offset = 1
    for value, j in taskInfo
      data[offset + j] = value

  # replace undefined with null, so arrayToCsv() works
  data = (x ? null for x in data)

  send(csv.arrayToCsv([data]))

exports.list = (head, req) ->
  report.requirePatientView(req)
  start(headers: report.csvHeaders('digit-symbol-report'))

  csvHeader = ['patientCode']

  send(csv.arrayToCsv([csvHeader]))

  patient.iterate(getRow, patientHandler)

## the rest of the header column name
#HEADER_SUFFIXES = [
#  report.VERSION_HEADER,
#  report.DATE_HEADER,
#].concat(report.DATA_QUALITY_HEADERS).concat([
#  'time',
#  'trials',
#  'timePerTrial',
#  'catchTrialScore'
#])
#
#
#
## combine task prefix with header suffix
#makeHeader = (prefix, suffix) ->
#  prefix + suffix[..0].toUpperCase() + suffix[1..]
#
#
#patientHandler = (patientRecord) ->
#  patientCode = patientRecord.patientCode
#
#  taskToInfo = {}
#  for encounter in patientRecord.encounters
#    for task in encounter.tasks
#      if task.finishedAt and task.eventLog? and task.name in LINE_TASKS
#        # only keep the first task per patient
#        if taskToInfo[task.name]
#          continue
#
#        # this isn't an off-by one; we discard the first trial because we
#        # don't know when the patient first gets the task
#        # using ? null because _.max() handles undefined differently
#        numTrials = _.max(
#          item?.state?.trialNum ? null for item in task.eventLog)
#
#        firstAction = _.find(task.eventLog, (item) -> item?.interpretation?)
#        totalTime = (task.finishedAt - firstAction.now) / 1000
#
#        # use the "interpretation" field if we have it (phasing this out)
#        intensitiesAtReversal = task?.interpretation?.intensitiesAtReversal
#
#        if not intensitiesAtReversal?
#          intensitiesAtReversal = (
#            item.state.intensity for item in task.eventLog \
#            when item?.interpretation?.reversal)
#
#        catchTrials = (
#          item.interpretation?.correct for item in task.eventLog \
#          when item?.state?.catchTrial is true
#        )
#
#        catchTrialScore = 'N/A'
#        if catchTrials.length > 0
#          catchTrialScore = ((catchTrials.filter((x)-> x if x == true).length \
#            / catchTrials.length) * 100)
#
#        if intensitiesAtReversal.length < MAX_REVERSALS
#          intensitiesAtReversal = intensitiesAtReversal.concat('') for i in \
#             [1..(MAX_REVERSALS - intensitiesAtReversal.length)]
#
#
#        taskToInfo[task.name] = [
#          report.getVersion(task),
#          report.getDate(task),
#        ].concat(report.getDataQualityCols(encounter)).concat([
#          totalTime,
#          numTrials,
#          totalTime / numTrials,
#          catchTrialScore
#        ]).concat(intensitiesAtReversal).concat(
#          catchTrials
#        )
#
#  if _.isEmpty(taskToInfo)
#    return
#
#  data = []
#
#
#  data[0] = patientCode
#  for taskName, i in LINE_TASKS
#    info = taskToInfo[taskName]
#    if info?
#      offset = i * COLUMNS_PER_TASK + 1
#      for value, j in info
#        data[offset + j] = value
#
#  # replace undefined with null, so arrayToCsv() works
#  data = (x ? null for x in data)
#
#  send(csv.arrayToCsv([data]))
#
#
#taskHeader = (prefix) ->
#  (makeHeader(prefix, suffix) for suffix in HEADER_SUFFIXES).concat(
#    (prefix + i for i in [1..MAX_REVERSALS]))
#
#exports.list = (head, req) ->
#  report.requirePatientView(req)
#  start(headers: report.csvHeaders('digit-symbol-report'))
#
#  csvHeader = ['patientCode']
#  for prefix in TASK_PREFIXES
#    csvHeader = csvHeader.concat(
#      taskHeader(prefix)
#    )
#
#  send(csv.arrayToCsv([csvHeader]))
#
#  patient.iterate(getRow, patientHandler)
