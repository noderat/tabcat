submitLoginForm = (event) ->
  event.preventDefault()
  form = $(event.target)
  messageP = form.find('#message')

  email = form.find('input[name=email]').val()
  if email.indexOf('@') is -1
    messageP.text('Please enter a valid email')
    return

  password = form.find('input[name=password]').val()
  if not password
    messageP.text('Please enter your password')
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
      when 401 then messageP.text(
        'Incorrect email or password')
      else messageP.text(xhr.textStatus or 'Unknown error')
  )

$(->
  $('#loginForm').on('submit', submitLoginForm)
  $('#loginForm button').removeAttr('disabled')
  message = tabcat.ui.readHashJSON().message
  if message?
    $('#message').text(message)
)
