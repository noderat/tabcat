###
Copyright (c) 2013, Regents of the University of California
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
# if it takes longer than 5 seconds to create an encounter, spill to
# local storage and continue
TIMEOUT = 5000

# Sandbox-specific stuff
SANDBOX_PATIENT_CODE = '0'
SANDBOX_WARNING = \
  "Sandbox mode is for testing. Don't use this with real patients!"


submitCreateEncounterForm = (event) ->
  event.preventDefault()
  form = $(event.target)

  patientCode = form.find('input[name=patientCode]').val()
  if not patientCode
    form.find('#error').text('Please enter a patient code')
    return

  TabCAT.Encounter.create(patientCode: patientCode, timeout: TIMEOUT).then(->
    window.location = TabCAT.UI.srcPath() ? 'tasks.html')


@initPage = ->
  TabCAT.UI.requireUser()

  if TabCAT.Encounter.isOpen()
    window.location = 'tasks.html'
    return

  TabCAT.UI.enableFastClick()
  TabCAT.UI.turnOffBounce()

  TabCAT.Console.start()

  $(->
    $form = $('#createEncounter').find('form')

    if TabCAT.Console.inSandbox()
      $form.find('input[name=patientCode]').val(SANDBOX_PATIENT_CODE).attr(
        'autocomplete', 'off')
      $form.find('p.warning').text(SANDBOX_WARNING)

    $form.on('submit', submitCreateEncounterForm)
    $form.find('button[type=submit]').removeAttr('disabled')
  )
  $(->
    if TabCAT.UI.srcPath()
      $('p.message').text('You need to create an encounter to view that page')
    else
      closedEncounterWith = TabCAT.UI.readHashJSON().closedEncounterWith
      if closedEncounterWith?
        $('p.message').text(
          'Closed encounter with Patient ' + closedEncounterWith)
  )
