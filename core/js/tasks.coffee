# TASK INFO

# Promise: get all design docs (most of which are tasks)
getAllDesignDocs = ->
  $.getJSON('../../_all_docs?' +
            'startkey="_design"&endkey="_design0"&include_docs=true').then(
    (response) ->
      (row.doc for row in response.rows))


# Promise: get a list of info about each task, with the keys index, icon,
# and description (index and icon are URLs), sorted by description.
#
# This automatically filters out design docs that aren't valid tasks.
getTaskInfo = ->
  $.when(getAllDesignDocs(), tabcat.encounter.getInfo()).then(
    (docs, encounterInfo) ->
      tasks = _.sortBy(
        _.compact(designDocToTaskInfo(doc) for doc in docs),
        # temporary hack: put Line Orientation task last
        #(item) -> item.description))
        (item) -> [item.description[0] is "L", item.description])

      started = {}
      finished = {}
      console.log(encounterInfo.tasks)
      for task in encounterInfo.tasks
        started[task.name] = true
        if task.finishedAt?
          finished[task.name] = true

      for task in tasks
        task.started = started[task.name]
        task.finished = finished[task.name]

      console.log(tasks)

      return tasks
  )


# convert a design doc to task info, or return undefined if it's not a
# valid task
designDocToTaskInfo = (doc) ->
  urlRoot = '../../' + doc._id

  c = doc.kanso?.config
  console.log(c)
  if (c? and c.index? and c.tabcat?.icon? and c.name? and c.description?)
    url: urlRoot + c.index
    icon: urlRoot + '/' + c.tabcat.icon
    description: c.description
    name: c.name


# get task info from the server, and then display an icon and a description
# for each task
showTasks = ->
  getTaskInfo().then((tasks) ->
    $('#taskList').empty()
    for task in tasks
      do (task) ->  # create a new scope to create separate bind() functions
        $div = $('<div></div>', class: 'task')
        $icon = $('<img>', class: 'icon', src: task.icon)
        $div.append($icon)
        $description = $('<span></span>', class: 'description')
        $description.text(task.description)
        $div.append($description)
        if task.started
          $status = $('<span></span>', class: 'status')
          if task.finished
            $status.text('finished')
          else
            $status.text('unfinished')
          $div.append($status)
        $('#taskList').append($div)
        $div.on('click', (event) -> window.location = task.url)
  )




# INTIALIZATION

tabcat.ui.requireLoginAndEncounter()

tabcat.ui.enableFastClick()

$(->
  tabcat.ui.updateStatusBar()
  showTasks()
  $('#closeEncounter').on('click', tabcat.ui.closeEncounter)
  $('#closeEncounter').removeAttr('disabled')
)
