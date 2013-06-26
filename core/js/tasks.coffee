# TASK INFO

# Promise: get all design docs (most of which are tasks)
getAllDesignDocs = ->
  $.getJSON('../../_all_docs?' +
            'startkey="_design"&endkey="_design0"&include_docs=true').then(
    (response) ->
      (row.doc for row in response.rows))

# Promise: get a list of info about each task, with the keys index, icon,
# and name (index and icon are URLs), sorted by name.
#
# This automatically filters out design docs that aren't valid tasks.
getTaskInfo = ->
  getAllDesignDocs().then((docs) ->
    _.sortBy(
      _.compact(designDocToTaskInfo(doc) for doc in docs),
      (item) -> item.name))

# convert a design doc to task info, or return undefined if it's not a
# valid task
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


# get task info from the server, and then display an icon and a name
# for each task
showTasks = ->
  getTaskInfo().then((info) ->
    $('#tasks').empty()
    for item in info
      do (item) ->  # create a new scope to create separate bind() functions
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
tabcat.ui.enableFastClick()

$(showTasks)
