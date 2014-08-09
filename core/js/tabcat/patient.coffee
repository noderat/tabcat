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
#
# Patient codes should always be uppercase. We may eventually restrict which
# characters they can contain.
@TabCAT ?= {}
TabCAT.Patient = {}

DATA_DB = 'tabcat-data'

# Promise: get basic patient info from the "patient" view. This contains
# an "encounters" field which has a list of all encounters
#
# options are passed through to TabCAT.Couch.getDoc
TabCAT.Patient.getHistory = (patientCode, options) ->
  patientCode ?= TabCAT.Encounter.getPatientCode()
  if not patientCode?
    return $.Deferred.resolve(null)

  options = _.extend(options ? {}, query:
    startkey: [patientCode]
    endkey: [patientCode, []])

  TabCAT.Couch.getDoc(
    DATA_DB, '_design/core/_list/dump/patient', options).then(
    (dump) ->
      return dump[0] ? null
  )


# merge info from oldDoc into doc. You rarely need to call this directly;
# TabCAT.Couch will do this automatically.
#
# Currently this just merges the encounterIds field and
# copies over fields that don't exist in doc. encounter IDs found in
# doc but not oldDoc are added to the END of encounterIds.
TabCAT.Patient.merge = (doc, oldDoc) ->

  if oldDoc.encounterIds?
    # use a set so that merge time isn't quadratic in number of encounters
    encounterIdSet = _.object([e, true] for e in oldDoc.encounterIds)

    mergedEncounterIds = oldDoc.encounterIds.slice(0)
    for e in (doc.encounterIds ? [])
      if not encounterIdSet[e]?
        mergedEncounterIds.push(e)

    doc.encounterIds = mergedEncounterIds

  # copy over fields filled in oldDoc but not doc
  for own key, value of oldDoc
    doc[key] ?= value

  return


# return a new patient doc (don't upload it)
#
# this coerces patientCode to be uppercase
TabCAT.Patient.newDoc = (patientCode) ->
  patientCode = String(patientCode ? 0).toUpperCase()

  return {
    _id: 'patient-' + patientCode
    type: 'patient'
    patientCode: patientCode
  }


# Promise: use a single design document to score tasks for a patient,
# returning a map from task ID to score.
#
# You'll need to do this once per design doc corresponding to tasks
# performed by a patient, which means you'll need to know which tasks
# a patient took, and what the corresponding design docs are.
#
# for an example, see console/js/patient-scoring.coffee
TabCAT.Patient.scoreTasksFromDesignDoc = (designDocId, patientCode) ->
  patientCode ?= TabCAT.Encounter.getPatientCode()
  if not patientCode?
    return $.Deferred.resolve(null)

  options = _.extend(options ? {}, query:
    startkey: [patientCode]
    endkey: [patientCode, []],
    include_docs: true)

  TabCAT.Couch.getDoc(
    DATA_DB, "#{designDocId}/_list/score/core/patient", options)
