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

      window.location = tabcat.ui.srcPath() ? 'create-encounter.html'
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
    if tabcat.ui.srcPath()?
      message = 'You need to log in to view that page'
    else if tabcat.ui.readHashJSON().loggedOut
      message = 'Logged out'
    else
      message = 'Please log in with your email and password'

    $('#message').text(message)

  $('#loginForm').on('submit', submitLoginForm)
  $('#loginForm button').removeAttr('disabled')
)
