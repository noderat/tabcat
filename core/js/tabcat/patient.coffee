# logic for opening encounters with patients.
#
# Patient codes should always be uppercase. We may eventually restrict which
# characters they can contain.
@tabcat ?= {}
tabcat.patient = {}

# merge info from oldDoc into doc
#
# currently this just merges the encounterIds field and
# copies over fields that don't exist in doc. encounter IDs found in
# doc but not oldDoc are added to the END of encounterIds.
tabcat.patient.merge = (oldDoc, doc) ->

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
