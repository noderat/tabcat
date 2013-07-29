# logic for creating patients and opening encounters with them.
#
# Patient codes should always be uppercase. We may eventually restrict which
# characters they can contain.

@tabcat ?= {}
tabcat.encounter = {}

# DB where we store patient and encounter docs
DATA_DB = 'tabcat-data'

# so we don't have to type window.localStorage in functions
localStorage = @localStorage


# get the patient code
tabcat.encounter.getPatientCode = ->
  localStorage.patientCode


# get the (random) ID of this encounter.
tabcat.encounter.getEncounterId = ->
  localStorage.encounterId


# is there an open encounter?
tabcat.encounter.isOpen = ->
  tabcat.encounter.getEncounterId()?


# get the encounter number. This should only be used in the UI, not
# stored in the database. May be undefined.
tabcat.encounter.getEncounterNum = ->
  try
    parseInt(localStorage.encounterNum)
  catch error
    undefined


# Promise: start an encounter and update patient doc and localStorage
# appropriately. Patient code will always be converted to all uppercase.
#
# Sample usage:
#
# tabcat.encounter.create(patientCode: "AAAAA").then(
#   (patientDoc) -> ... # proceed,
#   (xhr) -> ... # show error message on failure)
tabcat.encounter.create = (options) ->
  patientCode = String(options?.patientCode ? 0).toUpperCase()
  patientDocId = 'patient-' + patientCode
  encounterId = tabcat.couch.randomUUID()

  date = new Date

  encounterDoc =
    _id: encounterId
    type: 'encounter'
    patientCode: patientCode
    year: date.getFullYear()

  tabcat.clock.reset()

  updatePatientDoc = (patientDoc) ->
    patientDoc.encounterIds ?= []
    patientDoc.encounterIds.push(encounterId)
    tabcat.couch.putDoc(DATA_DB, patientDoc)

  $.when(tabcat.config.get(), tabcat.couch.getUser()).then(
    (configDoc, user) ->
      # store today's date, and timestamp if we're allowed
      if configDoc.limitedPHI
        encounterDoc.limitedPHI =
          month: date.getMonth()
          day: date.getDate()
          clockOffset: tabcat.clock.offset()

      encounterDoc.user = user
      tabcat.couch.putDoc(DATA_DB, encounterDoc).then(->
        $.getJSON("/#{DATA_DB}/#{patientDocId}").then(
          updatePatientDoc,
          (xhr) -> switch xhr.status
            when 404 then updatePatientDoc(
              _id: patientDocId, type: 'patient', patientCode: patientCode)
            else xhr  # pass failure through
        ).then((patientDoc) ->
          localStorage.patientCode = patientCode
          localStorage.encounterId = encounterId
          localStorage.encounterNum = patientDoc.encounterIds.length
          return patientDoc
        )
      )
  )


# finish the current patient encounter. this clears local storage even
# if there is a problem updating the encounter doc
#
# you will usually use tabcat.ui.closeEncounter(), which also redirects
# to the encounter page
tabcat.encounter.close = ->
  encounterId = tabcat.encounter.getEncounterId()
  now = tabcat.clock.now()
  tabcat.encounter.clear()

  if encounterId?
    $.getJSON("/#{DATA_DB}/#{encounterId}").then((encounterDoc) ->
      encounterDoc.finishedAt = now
      tabcat.couch.putDoc(DATA_DB, encounterDoc)
    )
  else
    $.Deferred().reject()


# clear local storage relating to the current encounter
tabcat.encounter.clear = ->
  localStorage.removeItem('patientCode')
  localStorage.removeItem('encounterId')
  localStorage.removeItem('encounterNum')
  tabcat.clock.clear()


# Promise: fetch info about an encounter.
#
# By default, we return info about the current encounter:
# - _id: doc ID for encounter (same as encounterId), if encounter exsists
# - clockOffset: real start time of encounter (if allowed by PHI settings)
# - patientCode: patient in encounter
# - tasks: list of task info, sorted by start time, with these fields:
#   - _id: doc ID for task
#   - name: name of task's design doc (e.g. "line-orientation")
#   - startedAt: timestamp for start of task (using encounter clock)
#   - finishedAt: timestamp for end of task, if task was finished
tabcat.encounter.getInfo = (encounterId) ->
  if not encounterId?
    encounterId = tabcat.encounter.getEncounterId()
    if not encounterId?
      return $.Deferred().resolve(null)

  encounterUrl = (
    "/#{DATA_DB}/_design/core/_view/encounter?startkey=" +
    encodeURIComponent(JSON.stringify([encounterId])) +
    '&endkey=' +
    # "" sorts just after null and all numbers
    encodeURIComponent(JSON.stringify([encounterId, ""])))

  $.getJSON(encounterUrl).then((results) ->
    info = {tasks: [], results: results}

    # arrange encounter, patients, and tasks into a single doc
    #
    # for now, don't bother with eventLog docs
    for {key: [__, startedAt, docType], value: doc} in results.rows
      if docType is 'encounter'
        $.extend(info, _.doc)
      else if docType is 'patient'
        # encounter number is determined from patient's list of encounters
        info.encounterNum = doc.encounterNum
      else if docType is 'task'
        doc.startedAt = startedAt
        info.tasks.push(doc)

    info.tasks = _.sortBy(info.tasks, (task) -> task.startedAt)

    return info
  )
