updateEncounterDivs = ->
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
    $('#message').text('Please enter a patient code')
    return

  tabcat.encounter.create(patientCode: patientCode).then(
    -> window.location = 'tasks.html')


tabcat.ui.requireLogin()

tabcat.ui.enableFastClick()

$(tabcat.ui.updateStatusBar)
$(updateEncounterDivs)
$(->
  $('#generatePatientCode')
    .on('click', clickGeneratePatientCode)
    .removeAttr('disabled')
)
$(->
  $('#createEncounterForm').on('submit', submitCreateEncounterForm)
  $('#createEncounterForm button[type=submit]').removeAttr('disabled')
)
