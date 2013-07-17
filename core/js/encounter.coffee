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

  tabcat.encounter.create(patientCode: patientCode).then(->
    window.location = tabcat.ui.srcPath() ? 'tasks.html')

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
  if tabcat.ui.srcPath()
    $('p.message').text('You need to create an encounter to view that page')
  else
    closedEncounterWith = tabcat.ui.readHashJSON().closedEncounterWith
    if closedEncounterWith?
      $('p.message').text(
        'Closed encounter with Patient ' + closedEncounterWith)

  $('#createEncounterForm').on('submit', submitCreateEncounterForm)
  $('#createEncounterForm button[type=submit]').removeAttr('disabled')

  $('#selectTasks').on('click', clickSelectTasks)
  $('#closeEncounter').on('click', clickCloseEncounter)

  updateStatusBarAndEncounterDivs()
)
