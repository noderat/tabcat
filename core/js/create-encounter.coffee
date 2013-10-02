submitCreateEncounterForm = (event) ->
  event.preventDefault()
  form = $(event.target)

  patientCode = form.find('input[name=patientCode]').val()
  if not patientCode
    form.find('#error').text('Please enter a patient code')
    return

  tabcat.encounter.create(patientCode: patientCode).then(->
    window.location = tabcat.ui.srcPath() ? 'tasks.html')


@initPage = ->
  tabcat.ui.requireUser()

  if tabcat.encounter.isOpen()
    window.location = 'tasks.html'
    return

  tabcat.ui.enableFastClick()
  tabcat.ui.turnOffBounce()

  $(->
    $form = $('#createEncounter').find('form')
    $form.on('submit', submitCreateEncounterForm)
    $form.find('button[type=submit]').removeAttr('disabled')
  )
  $(->
    if tabcat.ui.srcPath()
      $('p.message').text('You need to create an encounter to view that page')
    else
      closedEncounterWith = tabcat.ui.readHashJSON().closedEncounterWith
      if closedEncounterWith?
        $('p.message').text(
          'Closed encounter with Patient ' + closedEncounterWith)
  )
  $(tabcat.ui.updateStatusBar)

  tabcat.db.startSpilledDocSync()
