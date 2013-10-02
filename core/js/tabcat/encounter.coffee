# logic for opening encounters with patients.
@tabcat ?= {}
tabcat.encounter = {}

# DB where we store patient and encounter docs
DATA_DB = 'tabcat-data'

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# Get a copy of the CouchDB doc for this encounter
tabcat.encounter.get = ->
  try
    JSON.parse(localStorage.encounter)
  catch error
    null


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


# keep track of tasks finished during the encounter, in localStorate
tabcat.encounter.getTasksFinished = ->
  JSON.parse(localStorage.encounterTasksFinished ? '{}')


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
      month: date.getMonth()
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
tabcat.encounter.create = (options) ->
  tabcat.encounter.clear()
  tabcat.clock.reset()

  patientDoc = tabcat.patient.newDoc(options?.patientCode)

  $.when(tabcat.config.get()).then(
    (config) ->
      encounterDoc = tabcat.encounter.newDoc(patientDoc.patientCode, config)

      patientDoc.encounterIds = [encounterDoc._id]

      # if there's already a doc for the patient, our new encounter ID will
      # be appended to the existing patient.encounterIds
      tabcat.db.putDoc(
        DATA_DB, patientDoc, expectConflict: true).then(->

        tabcat.db.putDoc(DATA_DB, encounterDoc).then(->

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


# Promise: finish the current patient encounter. this clears local storage
# even if there is a problem updating the encounter doc. If there is no
# current encounter, does nothing.
#
# you will usually use tabcat.ui.closeEncounter(), which also redirects
# to the encounter page
tabcat.encounter.close = ->
  now = tabcat.clock.now()
  encounterDoc = tabcat.encounter.get()
  tabcat.encounter.clear()

  if encounterDoc?
    encounterDoc.finishedAt = now
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

    tabcat.couch.getDoc(DATA_DB, '_design/core/_view/patient',
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
