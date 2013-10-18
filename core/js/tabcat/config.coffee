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
