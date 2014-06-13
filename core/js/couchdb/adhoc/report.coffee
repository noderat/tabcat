# used to put prefixes before headers
exports.capitalize = (s) ->
  s[..0].toUpperCase + s[1..]

# current date (ISO format), for report name
exports.today = ->
  (new Date()).toISOString()[..9]


exports.VERSION_HEADER = 'version'

# get version from task
exports.getVersion = (task) ->
  task.version ? null

exports.DATE_HEADER = 'date'

# get date from task (ISO version)
exports.getDate = (task) ->
  timestamp = task.limitedPHI?.clockOffset
  if timestamp?
    # note that this the server's local time
    (new Date(timestamp)).toISOString()[..9]
  else
    null


exports.DATA_QUALITY_HEADERS = [
  'goodForResearch', 'qualityIssues', 'adminComments']

# get data quality values from task
exports.getDataQualityCols = (encounter) ->
  notes = encounter.administrationNotes
  goodForResearch = null
  if notes?.goodForResearch?  # use 0/1 rather than false/true
    goodForResearch = Number(notes.goodForResearch)
  qualityIssues = (notes?.qualityIssues ? []).join(', ')
  adminComments = notes?.comments ? null

  return [goodForResearch, qualityIssues, adminComments]
