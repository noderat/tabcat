# used to put prefixes before headers
exports.requirePatientView = (req) ->
  keyType = req.path[req.path.length - 1]
  if not (req.path.length is 6 and keyType is 'patient')
    throw new Error('You may only dump the patient view')

# use with start() to print headers: start(headers: csvHeaders('my-report'))
exports.csvHeaders = (reportName) ->
  'Content-Disposition': (
    "attachment; filename=\"stargazer-report-#{today()}.csv"),
  'Content-Type': 'text/csv'


# current date (ISO format), for report name
exports.today = today = ->
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
