updateStatusBarAndEncounterDivs = ->
  tabcat.ui.updateStatusBar()
  if tabcat.encounter.isOpen()
    $('#noEncounter').hide()
    $('#encounter').show()
  else
    $('#encounter').hide()
    $('#noEncounter').show()

submitCreateEncounterForm = (event) ->
  event.preventDefault()
  form = $(event.target)

  patientCode = form.find('input[name=patientCode]').val()
  if not patientCode
    form.find('#error').text('Please enter a patient code')
    return

  redirPath = tabcat.ui.readHashJSON().redirPath
  # only allow redirects to a different path, not to other sites
  if not (redirPath? and redirPath.substring(0, 1) is '/')
    redirPath = 'tasks.html'

  tabcat.encounter.create(patientCode: patientCode).then(
    -> window.location = redirPath)

clickSelectTasks = (event) ->
  window.location = 'tasks.html'

clickCloseEncounter = (event) ->
  patientCode = tabcat.encounter.getPatientCode()
  tabcat.encounter.close().always(->
    $('#noEncounter p.message').text(
      'Closed encounter with Patient ' + patientCode)
    updateStatusBarAndEncounterDivs())

tabcat.ui.requireLogin()

tabcat.ui.enableFastClick()

$(->
  message = tabcat.ui.readHashJSON().message
  if message
    $('p.message').text(message)

  $('#createEncounterForm').on('submit', submitCreateEncounterForm)
  $('#createEncounterForm button[type=submit]').removeAttr('disabled')

  $('#selectTasks').on('click', clickSelectTasks)
  $('#closeEncounter').on('click', clickCloseEncounter)

  updateStatusBarAndEncounterDivs()
)
