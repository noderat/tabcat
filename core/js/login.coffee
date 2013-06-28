submitLoginForm = (event) ->
  event.preventDefault()
  form = $(event.target)
  $.post('/_session', form.serialize()).then(
    -> window.location = 'tasks.html',
    (xhr) -> switch xhr.status
      when 401 then $('p.error', form).text(
        'Incorrect username or password')
      else $('p.error', form).text(xhr.textStatus or 'Unknown error')
  )

$(->
  $('form.login').on('submit', submitLoginForm)
  $('form.login button').removeAttr('disabled')
)
