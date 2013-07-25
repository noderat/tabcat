clickIAmTheExaminer = (event) ->
  tabcat.task.patientHasDevice(false)
  window.location = tabcat.ui.srcPath() ? 'tasks.html'

tabcat.ui.linkEmToPercentOfHeight($(document.body))
$('#returnToExaminer').show()
$(->
  $('#iAmTheExaminer').on('click', clickIAmTheExaminer)
  $('#iAmTheExaminer').removeAttr('disabled')
)
