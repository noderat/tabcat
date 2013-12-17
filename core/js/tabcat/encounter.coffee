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
@tabcat ?= {}
tabcat.encounter = {}

# DB where we store patient and encounter docs
DATA_DB = 'tabcat-data'

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# Get a copy of the CouchDB doc for this encounter
tabcat.encounter.get = ->
  if localStorage.encounter?
    try JSON.parse(localStorage.encounter)


# get the patient code
tabcat.encounter.getPatientCode = ->
  tabcat.encounter.get()?.patientCode


# get the (random) ID of this encounter.
tabcat.encounter.getId = ->
  tabcat.encounter.get()?._id


# is there an open encounter?
tabcat.encounter.isOpen = ->
  tabcat.encounter.get()?


# get the encounter number. This should only be used in the UI, not
# stored in the database. null if unknown.
tabcat.encounter.getNum = ->
  encounterNum = undefined
  try
    encounterNum = parseInt(localStorage.encounterNum)

  if not encounterNum? or _.isNaN(encounterNum)
    return null
  else
    return encounterNum


# keep track of tasks finished during the encounter, in localStorage
tabcat.encounter.getTasksFinished = ->
  (try JSON.parse(localStorage.encounterTasksFinished)) ? {}


# mark a task as finished in localStorage.
#
# tabcat.task.finish() does this automatically
tabcat.encounter.markTaskFinished = (taskName) ->
  finished = tabcat.encounter.getTasksFinished()
  finished[taskName] = true
  localStorage.encounterTasksFinished = JSON.stringify(finished)
  return


# return a new encounter doc (don't upload it)
#
# Call tabcat.clock.reset() before this so that time fields are properly set.
tabcat.encounter.newDoc = (patientCode, configDoc) ->
  clockOffset = tabcat.clock.offset()
  date = new Date(clockOffset)

  doc =
    _id: tabcat.couch.randomUUID()
    type: 'encounter'
    patientCode: patientCode
    year: date.getFullYear()

  user = tabcat.user.get()
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
# tabcat.encounter.create(patientCode: "AAAAA").then(
#   (-> ... # proceed),
#   (xhr) -> ... # show error message on failure
# )
#
# You can set a timeout in milliseconds with options.timeout
tabcat.encounter.create = (options) ->
  now = $.now()
  tabcat.encounter.clear()
  tabcat.clock.reset()

  patientDoc = tabcat.patient.newDoc(options?.patientCode)

  $.when(tabcat.config.get(timeout: options?.timeout)).then(
    (config) ->
      encounterDoc = tabcat.encounter.newDoc(patientDoc.patientCode, config)

      patientDoc.encounterIds = [encounterDoc._id]

      # if there's already a doc for the patient, our new encounter ID will
      # be appended to the existing patient.encounterIds
      tabcat.db.putDoc(
        DATA_DB, patientDoc,
        expectConflict: true, now: now, timeout: options?.timeout).then(->

        tabcat.db.putDoc(
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
# you will usually use tabcat.ui.closeEncounter(), which also redirects
# to the encounter page
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
tabcat.encounter.close = (options) ->
  now = tabcat.clock.now()
  encounterDoc = tabcat.encounter.get()
  tabcat.encounter.clear()

  if encounterDoc?
    encounterDoc.finishedAt = now
    if options?.administrationNotes?
      encounterDoc.administrationNotes = options.administrationNotes
    tabcat.db.putDoc(DATA_DB, encounterDoc)
  else
    $.Deferred().resolve()


# clear local storage relating to the current encounter
tabcat.encounter.clear = ->
  localStorage.removeItem('encounter')
  localStorage.removeItem('encounterNum')
  localStorage.removeItem('encounterTasksFinished')
  tabcat.clock.clear()


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
tabcat.encounter.getInfo = (encounterId, patientCode) ->
  if not encounterId?
    encounterId = tabcat.encounter.getId()
    patientCode = tabcat.encounter.getPatientCode()

    if not (encounterId? and patientCode?)
      return $.Deferred().resolve(null)

  if patientCode?
    patientCodePromise = $.Deferred().resolve(patientCode)
  else
    patientCodePromise = tabcat.couch.getDoc(DATA_DB, encounterId).then(
      (encounterDoc) -> encounterDoc.patientCode)

  patientCodePromise.then((patientCode) ->

    tabcat.couch.getDoc(DATA_DB, '_design/core/_view/patient', query:
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
