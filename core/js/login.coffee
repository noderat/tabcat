submitLoginForm = (event) ->
  event.preventDefault()
  form = $(event.target)
  alert(form.serialize())

$(->
  $('form.login').on('submit', submitLoginForm)
  $('form.login button').removeAttr('disabled')
)
