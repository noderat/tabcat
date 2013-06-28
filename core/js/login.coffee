submitLoginForm = (event) ->
  event.preventDefault()
  form = $(event.target)
  errorElement = $('p.error', form)

  name = $('input[name=name]', form).val()
  if name.indexOf('@') is -1
    errorElement.text('Please enter a valid email')
    return

  password = $('input[name=password]', form).val()
  if not password
    errorElement.text('Please enter your password')
    return

  $.post('/_session', form.serialize()).then(
    -> window.location = 'tasks.html',
    (xhr) -> switch xhr.status
      when 401 then errorElement.text(
        'Incorrect email or password')
      else errorElement.text(xhr.textStatus or 'Unknown error')
  )

$(->
  $('form.login').on('submit', submitLoginForm)
  $('form.login button').removeAttr('disabled')
)
