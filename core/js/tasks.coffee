# TASK INFO

getAllDesignDocs = ->
  $.getJSON('../../_all_docs?' +
            'startkey="_design"&endkey="_design0"&include_docs=true').then(
    (response) ->
      (row.doc for row in response.rows))

getTaskInfo = ->
  getAllDesignDocs().then((docs) ->
    _.sortBy(
      _.compact(designDocToTaskInfo(doc) for doc in docs),
      (item) -> item.name))


designDocToTaskInfo = (doc) ->
  urlRoot = '../../' + doc._id

  index = doc?.kanso?.config?.index
  icon = doc?.kanso?.config?.tabcat?.icon
  name = doc?.kanso?.config?.description ? doc?.kanso?.config?.name

  if not (index and icon and name)
    undefined
  else
    url: urlRoot + index
    icon: urlRoot + '/' + icon
    name: name


showTasks = ->
  getTaskInfo().then((info) ->
    $('#tasks').empty()
    for item in info
      div = $('<div></div>', class: 'task')
      img = $('<img>', class: 'icon', src: item.icon)
      div.append(img)
      span = $('<span></span>', class: 'name')
      span.text(item.name)
      div.append(span)
      div.bind('click', (event) -> window.location = item.url)
      $('#tasks').append(div)
  )


# INTIALIZATION
$(showTasks)
