clickIAmTheExaminer = (event) ->
  redirPath = tabcat.ui.readHashJSON().redirPath
  # only allow redirects to a different path, not to other sites
  if not (redirPath? and redirPath.substring(0, 1) is '/')
    redirPath = 'tasks.html'

  window.location = redirPath

tabcat.ui.linkFontSizeToHeight($(document.body), 2)
$(->
  $('#iAmTheExaminer').on('click', clickIAmTheExaminer)
  $('#iAmTheExaminer').removeAttr('disabled')
)
