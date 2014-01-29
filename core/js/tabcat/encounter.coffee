###
Copyright (c) 2013, Regents of the University of California
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
# logic for opening encounters with patients.
@TabCAT ?= {}
TabCAT.Encounter = {}

# DB where we store patient and encounter docs
DATA_DB = 'tabcat-data'

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# Get a copy of the CouchDB doc for this encounter
TabCAT.Encounter.get = ->
  if localStorage.encounter?
    try JSON.parse(localStorage.encounter)


# get the patient code
TabCAT.Encounter.getPatientCode = ->
  TabCAT.Encounter.get()?.patientCode


# get the (random) ID of this encounter.
TabCAT.Encounter.getId = ->
  TabCAT.Encounter.get()?._id


# is there an open encounter?
TabCAT.Encounter.isOpen = ->
  TabCAT.Encounter.get()?


# get the encounter number. This should only be used in the UI, not
# stored in the database. null if unknown.
TabCAT.Encounter.getNum = ->
  encounterNum = undefined
  try
    encounterNum = parseInt(localStorage.encounterNum)

  if not encounterNum? or _.isNaN(encounterNum)
    return null
  else
    return encounterNum


# keep track of tasks finished during the encounter, in localStorage
TabCAT.Encounter.getTasksFinished = ->
  (try JSON.parse(localStorage.encounterTasksFinished)) ? {}


# mark a task as finished in localStorage.
#
# TabCAT.Task.finish() does this automatically
TabCAT.Encounter.markTaskFinished = (taskName) ->
  finished = TabCAT.Encounter.getTasksFinished()
  finished[taskName] = true
  localStorage.encounterTasksFinished = JSON.stringify(finished)
  return


# return a new encounter doc (don't upload it)
#
# Call TabCAT.Clock.reset() before this so that time fields are properly set.
TabCAT.Encounter.newDoc = (patientCode, configDoc) ->
  clockOffset = TabCAT.Clock.offset()
  date = new Date(clockOffset)

  doc =
    _id: TabCAT.Couch.randomUUID()
    type: 'encounter'
    patientCode: patientCode
    version: TabCAT.version
    year: date.getFullYear()

  user = TabCAT.User.get()
  if user?
    doc.user = user

  if configDoc?.limitedPHI
    doc.limitedPHI =
      # in JavaScript, January is 0, February is 1, etc.
      month: date.getMonth() + 1
      day: date.getDate()
      clockOffset: clockOffset

  return doc


# Promise: start an encounter and update patient doc and localStorage
# appropriately. Patient code will always be converted to all uppercase.
#
# Sample usage:
#
# TabCAT.Encounter.create(patientCode: "AAAAA").then(
#   (-> ... # proceed),
#   (xhr) -> ... # show error message on failure
# )
#
# You can set a timeout in milliseconds with options.timeout
TabCAT.Encounter.create = (options) ->
  now = $.now()
  TabCAT.Encounter.clear()
  TabCAT.Clock.reset()

  patientDoc = TabCAT.Patient.newDoc(options?.patientCode)

  $.when(TabCAT.Config.get(timeout: options?.timeout)).then(
    (config) ->
      encounterDoc = TabCAT.Encounter.newDoc(patientDoc.patientCode, config)

      patientDoc.encounterIds = [encounterDoc._id]

      # if there's already a doc for the patient, our new encounter ID will
      # be appended to the existing patient.encounterIds
      TabCAT.DB.putDoc(
        DATA_DB, patientDoc,
        expectConflict: true, now: now, timeout: options?.timeout).then(->

        TabCAT.DB.putDoc(
          DATA_DB, encounterDoc, now: now, timeout: options?.timeout).then(->

          # update localStorage
          localStorage.encounter = JSON.stringify(encounterDoc)
          # only show encounter number if we're online
          if encounterDoc._rev
            localStorage.encounterNum = patientDoc.encounterIds.length
          else
            localStorage.removeItem('encounterNum')
          return
        )
      )
  )


# Promise (can't fail): finish the current patient encounter. this clears
# local storage even if there is a problem updating the encounter doc. If
# there is no current encounter, does nothing.
#
# options:
# - administrationNotes: notes used to determine the quality of the data
#   collected in the encounter. These fields are recommended:
#   - goodForResearch (boolean): is this data useful for research?
#   - qualityIssues (sorted list of strings): specific patient issues
#     affecting data quality:
#     - behavior: behavioral disturbances
#     - education: minimal education
#     - effort: lack of effort
#     - hearing: hearing impairment
#     - motor: motor difficulties
#     - secondLanguage: e.g. ESL, different from "speech"
#     - speech: speech difficulties
#     - unreliable: unreliable informant
#     - visual: visual impairment
#     - other: (should explain in "comments")
#   - comments (text): free-form comments on the encounter
#
# goodForResearch should be required by the UI, but neither administrationNotes
# nor goodForResearch are required by this method.
TabCAT.Encounter.close = (options) ->
  now = TabCAT.Clock.now()
  encounterDoc = TabCAT.Encounter.get()
  TabCAT.Encounter.clear()

  if encounterDoc?
    encounterDoc.finishedAt = now
    if options?.administrationNotes?
      encounterDoc.administrationNotes = options.administrationNotes
    TabCAT.DB.putDoc(DATA_DB, encounterDoc)
  else
    $.Deferred().resolve()


# clear local storage relating to the current encounter
TabCAT.Encounter.clear = ->
  localStorage.removeItem('encounter')
  localStorage.removeItem('encounterNum')
  localStorage.removeItem('encounterTasksFinished')
  TabCAT.Clock.clear()


# Promise: fetch info about an encounter.
#
# Returns:
# - _id: doc ID for encounter (same as encounterId), if encounter exsists
# - limitedPHI.clockOffset: real start time of encounter
# - patientCode: patient in encounter
# - tasks: list of task info, sorted by start time, with these fields:
#   - _id: doc ID for task
#   - name: name of task's design doc (e.g. "line-orientation")
#   - startedAt: timestamp for start of task (using encounter clock)
#   - finishedAt: timestamp for end of task, if task was finished
# - type: always "encounter"
# - year: year encounter started
#
# By default (no args), we return info about the current encounter.
#
# You may provide patientCode if you know it; otherwise we'll look it up.
TabCAT.Encounter.getInfo = (encounterId, patientCode) ->
  if not encounterId?
    encounterId = TabCAT.Encounter.getId()
    patientCode = TabCAT.Encounter.getPatientCode()

    if not (encounterId? and patientCode?)
      return $.Deferred().resolve(null)

  if patientCode?
    patientCodePromise = $.Deferred().resolve(patientCode)
  else
    patientCodePromise = TabCAT.Couch.getDoc(DATA_DB, encounterId).then(
      (encounterDoc) -> encounterDoc.patientCode)

  patientCodePromise.then((patientCode) ->

    TabCAT.Couch.getDoc(DATA_DB, '_design/core/_view/patient', query:
      startkey: [patientCode, encounterId]
      endkey: [patientCode, encounterId, []]).then((results) ->

      info = {_id: encounterId, patientCode: patientCode, tasks: []}

      # arrange encounter, patients, and tasks into a single doc
      # TODO: this code is similar to lib/app/dumpList(); merge common code?
      for {key: [__, ___, taskId, startedAt], value: doc} in results.rows
        switch doc.type
          when 'encounter'
            $.extend(info, doc)
          when 'encounterNum'
            info.encounterNum = doc.encounterNum
          when 'task'
            doc.startedAt = startedAt
            info.tasks.push(_.extend({_id: taskId}, _.omit(doc, 'type')))

      info.tasks = _.sortBy(info.tasks, (task) -> task.startedAt)

      return info
    )
  )
