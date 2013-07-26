# Tabcat-specific configs, such as PHI (Protected Health Information) level
#
# Configs are stored in a document with the ID "config" in the tabcat-data DB
# (this will eventually allow multiple data DBs with different configurations)

# for more info about PHI see:
# http://www.research.ucsf.edu/chr/HIPAA/chrHIPAAfaq.asp

@tabcat ?= {}
tabcat.config = {}

# DB where config doc is stored
DATA_DB = 'tabcat-data'


# Helper for tabcat.config.get()
fixConfig = (configDoc) ->
  configDoc._id ?= 'config'
  configDoc.type ?= 'config'

  configDoc.PHI = !!configDoc.PHI
  configDoc.limitedPHI = configDoc.PHI or !!configDoc.limitedPHI

  return configDoc


# Promise: get the current config, based on the "config" document
#
# Fields we will make sure are filled in the config doc returned:
#
# - PHI (boolean): do we allow full PHI? (e.g. name of the patient)
# - limitedPHI (boolean): do we allow Limited Dataset PHI? This allows us to
#   store dates, timestamps, city, state, and zipcode. Implied by "PHI".
#
# - _id: should always be "config"
# - type: should always be "config"
tabcat.config.get = _.once(->
  $.getJSON("/#{DATA_DB}/config").then(
    (configDoc) -> fixConfig(configDoc),
    (xhr) -> switch xhr.status
      when 404 then $.Deferred().resolve(fixConfig({}))
      else xhr  # pass through failure
  )
)
