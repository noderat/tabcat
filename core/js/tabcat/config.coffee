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

# so we don't have to type window.localStorage in functions
localStorage = @localStorage

# Helper for tabcat.config.get()
fixAndRememberConfig = (configDoc) ->
  # strip document fields; we just want the configs
  config = _.omit(configDoc, '_id', '_rev', 'type')

  config.PHI = !!config.PHI
  config.limitedPHI = config.PHI or !!config.limitedPHI

  # store locally. Remove _rev, since this is an offline document
  localStorage.config = JSON.stringify(config)

  return config


# Promise (can't fail): get the current config from the DB, falling back
# to configs in localStorage, or the default.
#
# Fields we will make sure are filled in the config doc returned:
#
# - PHI (boolean): do we allow full PHI? (e.g. name of the patient)
# - limitedPHI (boolean): do we allow Limited Dataset PHI? This allows us to
#   store dates, timestamps, city, state, and zipcode. Implied by "PHI".
#
# - _id: should always be "config"
# - type: should always be "config"
#
# You can set a timeout in milliseconds with options.timeout
tabcat.config.get = _.once((options) ->
  tabcat.couch.getDoc(DATA_DB, 'config', timeout: options?.timeout).then(
    (configDoc) -> fixAndRememberConfig(configDoc),
    (xhr) ->
      if xhr.status is 404
        # config doesn't exist
        $.Deferred().resolve(fixAndRememberConfig({}))
      else
        # offline or can't authenticate, use stored config
        $.Deferred().resolve((try JSON.parse(localStorage.config)) ? {})
  )
)
