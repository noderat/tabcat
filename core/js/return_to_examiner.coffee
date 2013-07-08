clickIAmTheExaminer = (event) ->
  tabcat.task.patientHasDevice(false)

  redirPath = tabcat.ui.readHashJSON().redirPath
  # only allow redirects to a different path, not to other sites
  if not (redirPath? and redirPath.substring(0, 1) is '/')
    redirPath = 'tasks.html'

  window.location = redirPath

tabcat.ui.linkEmToPercentOfHeight($(document.body))
$(->
  $('#iAmTheExaminer').on('click', clickIAmTheExaminer)
  $('#iAmTheExaminer').removeAttr('disabled')
)
