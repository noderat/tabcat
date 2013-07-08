updateStatusBarAndEncounterDivs = ->
  tabcat.ui.updateStatusBar()
  if tabcat.encounter.getEncounterId()?
    $('#noEncounter').hide()
    $('#encounter').show()
  else
    $('#encounter').hide()
    $('#noEncounter').show()

clickGeneratePatientCode = (event) ->
  event.preventDefault()
  $('#createEncounterForm input[name=patientCode]').val(
    tabcat.encounter.generatePatientCode())

submitCreateEncounterForm = (event) ->
  event.preventDefault()
  form = $(event.target)

  patientCode = form.find('input[name=patientCode]').val()
  if not patientCode
    $('#error').text('Please enter a patient code')
    return

  tabcat.encounter.create(patientCode: patientCode).then(
    -> window.location = 'tasks.html')

clickSelectTasks = (event) ->
  window.location = 'tasks.html'

clickCloseEncounter = (event) ->
  patientCode = tabcat.encounter.getPatientCode()
  tabcat.encounter.close().always(->
    $('#error').text('Closed encounter with Patient ' + patientCode)
    updateStatusBarAndEncounterDivs())

tabcat.ui.requireLogin()

tabcat.ui.enableFastClick()

$(updateStatusBarAndEncounterDivs)
$(->
  $('#generatePatientCode')
    .on('click', clickGeneratePatientCode)
    .removeAttr('disabled')
)
$(->
  $('#createEncounterForm').on('submit', submitCreateEncounterForm)
  $('#createEncounterForm button[type=submit]').removeAttr('disabled')
)
$(-> $('#selectTasks').on('click', clickSelectTasks))
$(-> $('#closeEncounter').on('click', clickCloseEncounter))
