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
    user = tabcat.user.get()
    if user
      if tabcat.encounter.isOpen() and not window.location.hash
        $('#message').text('Continuing encounter...')
        window.location = 'tasks.html'
      else
        $('#message').text('Please enter your password to continue')
        $('#loginForm').attr('autocomplete', 'off')
        $('#loginForm').find('input[name=email]').val(user)
    else if tabcat.ui.srcPath()?
      $('#message').text('You need to log in to view that page')
    else if tabcat.ui.readHashJSON().loggedOut
      $('#message').text('Logged out')
    else
      $('#message').text('Please log in with your email and password')

    $('#loginForm').on('submit', submitLoginForm)
    $('#loginForm button').removeAttr('disabled')
  )
