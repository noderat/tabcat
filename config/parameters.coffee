config =
  manifest_file: 'cache.manifest'
  coffeelint: true
  targets:
    console:
      paths: [
        './console/js'
      ]
      enabled: true
    core:
      paths: [
        './core/js/couchdb',
        './core/js/couchdb/adhoc'
      ]
      enabled: true

module.exports = config