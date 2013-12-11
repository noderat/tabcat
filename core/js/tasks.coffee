###
Copyright (c) 2013, Regents of the University of California
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  1. Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
# TASK INFO

# DB where design docs and task content is stored
TABCAT_DB = 'tabcat'


# Promise: get an object containing "batteries" and "tasks"; these each
# map battery/task name to the corresponding info from the design docs.
#
# This also adds a "urlRoot" and "finished" field to each task
#
# options is the same as for tabcat.couch.getAllDesignDocs
@getTaskInfo = (options) ->
  tabcat.couch.getAllDesignDocs(TABCAT_DB).then(
    (designDocs) ->
      batteries = {}
      tasks = {}

      finished = tabcat.encounter.getTasksFinished()

      for designDoc in designDocs
        kct = designDoc.kanso?.config?.tabcat
        if kct?
          _.extend(batteries, kct.batteries)

          # add urlRoot and finished to each task
          if kct.tasks?
            urlRoot = "/#{TABCAT_DB}/#{designDoc._id}/"
            for own name, task of kct.tasks
              tasks[name] = _.extend(task,
                finished: !!finished[name]
                urlRoot: urlRoot
              )

      return {batteries: batteries, tasks: tasks}
    )


# get task info from the server, and then display an icon and a description
# for each task
showTasks = ->
  getTaskInfo().then((taskInfo) ->
    $('#taskList').empty()

    # alphabetize tasks
    tasks = _.sortBy(_.values(taskInfo.tasks), (t) -> t.description)

    for task in tasks
      do (task) ->  # create a new scope to create separate bind() functions
        if not (task.start? and task.description?)
          return

        $div = $('<div></div>', class: 'task')

        if task.icon?
          iconUrl = task.urlRoot + task.icon
        else
          # default to TabCAT icon
          iconUrl = 'img/icon.png'

        if task.finished
          # make the icon the background, and the checkmark the foreground
          # TODO: use absolute positioning and z-indexes to do a real overlay
          $icon = $('<img>', class: 'icon', src: 'img/check-overlay.png')
          $icon.css('background-image', "url(#{iconUrl})")
        else
          $icon = $('<img>', class: 'icon', src: iconUrl)
        $div.append($icon)

        $description = $('<span></span>', class: 'description')
        $description.text(task.description)
        $div.append($description)

        $('#taskList').append($div)

        startUrl = task.urlRoot + task.start
        $div.on('click', (event) -> window.location = startUrl)
  )


# initialization
@initPage = ->
  tabcat.ui.requireUserAndEncounter()

  tabcat.ui.enableFastClick()

  $(->
    tabcat.ui.updateStatusBar()
    showTasks()
    $('#closeEncounter').on('click', tabcat.ui.closeEncounter)
    $('#closeEncounter').removeAttr('disabled')
  )

  tabcat.db.startSpilledDocSync()
