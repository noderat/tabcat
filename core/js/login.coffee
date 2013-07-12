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

  tabcat.couch.login(name: email, password: password).then(
    (->
      # don't magically restart an encounter just because it's sitting
      # around in localStorage
      tabcat.encounter.clear()

      redirPath = tabcat.ui.readHashJSON().redirPath
      # only allow redirects to a different path, not to other sites
      if not (redirPath? and redirPath.substring(0, 1) is '/')
        redirPath = 'encounter.html'

      window.location = redirPath
    ),
    (xhr) -> switch xhr.status
      when 401 then errorP.text(
        'Incorrect email or password')
      else errorP.text(xhr.textStatus or 'Unknown error')
  )


$(->
  if tabcat.encounter.isOpen() and not window.location.hash
    $('#message').text('Continuing encounter...')
    window.location = 'tasks.html'
  else
    message = tabcat.ui.readHashJSON().message
    $('#message').text(
      message ? 'Please log in with your email and password')

  $('#loginForm').on('submit', submitLoginForm)
  $('#loginForm button').removeAttr('disabled')
)
