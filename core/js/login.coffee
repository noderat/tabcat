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
submitLoginForm = (event) ->
  event.preventDefault()
  form = $(event.target)
  errorP = form.find('#error')

  email = form.find('input[name=email]').val()
  if email.indexOf('@') is -1
    errorP.text('Please enter a valid email')
    return

  password = form.find('input[name=password]').val()
  if not password
    errorP.text('Please enter your password')
    return

  tabcat.ui.login(email, password).then(
    null,
    (xhr) -> switch xhr.status
      when 401 then errorP.text(
        'Incorrect email or password')
      else errorP.text(xhr.textStatus or 'Unknown error')
  )

@initPage = ->
  tabcat.ui.enableFastClick()
  tabcat.ui.turnOffBounce()

  $(->
    # continue session/encounter if user is restarting TabCAT
    if tabcat.user.get() and not window.location.hash

      # trigger asking user for password if no valid session cookie
      tabcat.task.patientHasDevice(false)

      if tabcat.encounter.isOpen()
        $('#message').text('Continuing encounter...')
        window.location = 'tasks.html'
      else
        $('#message').text('Continuing session...')
        window.location = 'create-encounter.html'
      return

    if tabcat.ui.srcPath()?
      $('#message').text('You need to log in to view that page')
    else if tabcat.ui.readHashJSON().loggedOut
      $('#message').text('Logged out')
    else
      $('#message').text('Please log in with your email and password')

    $('#loginForm').on('submit', submitLoginForm)
    $('#loginForm button').removeAttr('disabled')
  )
