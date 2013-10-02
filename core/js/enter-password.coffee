submitEnterPasswordForm = (event) ->
  event.preventDefault()
  form = $(event.target)
  errorP = form.find('#error')

  password = form.find('input[name=password]').val()
  if not password
    errorP.text('Please enter your password')
    return

  tabcat.ui.login(tabcat.user.get(), password).then(
    null,
    (xhr) -> switch xhr.status
      when 401 then errorP.text(
        'Incorrect email or password')
      else errorP.text(xhr.textStatus or 'Unknown error')
  )


@initPage = ->
  tabcat.ui.enableFastClick()
  tabcat.ui.turnOffBounce()

  user = tabcat.user.get()
  if not user?
    window.location = 'login.html'
    return

  $(->
    $('#howToLogout').text(
      'Not ' + user + '? Tap the button in the upper right' +
      ' to log in as a different user.')

    $loginForm = $('#loginForm')
    $loginForm.find('input[name=email]').val(user)
    $loginForm.on('submit', submitEnterPasswordForm)
    $loginForm.find('button').removeAttr('disabled')
  )
  $(tabcat.ui.updateStatusBar)
