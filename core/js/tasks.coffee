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
    (designDocs, encounter) ->
      taskInfo = _.sortBy(
        _.compact(designDocToTaskInfo(doc) for doc in designDocs),
        # temporary hack: put Line Orientation task last
        #(item) -> item.description))
        (item) -> [item.description[0] is "L", item.description])

      # add info about which tasks were finished
      finished = _.object(
        [task.name, true] for task in encounter.tasks when task.finishedAt?)
      for task in taskInfo
        task.finished = finished[task.name]

      return taskInfo
  )


# convert a design doc to task info, or return undefined if it's not a
# valid task
designDocToTaskInfo = (doc) ->
  urlRoot = '../../' + doc._id

  c = doc.kanso?.config
  if (c? and c.index? and c.tabcat?.icon? and c.name? and c.description?)
    url: urlRoot + c.index
    icon: urlRoot + '/' + c.tabcat.icon
    description: c.description
    name: c.name


# get task info from the server, and then display an icon and a description
# for each task
showTasks = ->
  getTaskInfo().then((taskInfo) ->
    $('#taskList').empty()
    for task in taskInfo
      do (task) ->  # create a new scope to create separate bind() functions
        $div = $('<div></div>', class: 'task')

        if task.finished
          # make the icon the background, and the checkmark the foreground
          # TODO: use absolute positioning and z-indexes to do a real overlay
          $icon = $('<img>', class: 'icon', src: 'img/check-overlay.png')
          $icon.css('background-image', 'url(' + task.icon + ')')
        else
          $icon = $('<img>', class: 'icon', src: task.icon)
        $div.append($icon)

        $description = $('<span></span>', class: 'description')
        $description.text(task.description)
        $div.append($description)

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
