###
Copyright (c) 2013-2014, Regents of the University of California
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

# get task info from the server, and then display an icon and a description
# for each task
showTasks = ->
  TabCAT.Task.getBatteriesAndTasks().then((bt) ->
    $('#taskList').empty()

    batteries = _.sortBy(_.values(bt.batteries), (b) -> b.description)
    tasksByName = bt.tasks

    # add a fake battery for all tasks
    allTaskNames = _.sortBy(
      _.keys(tasksByName), (name) -> tasksByName[name].description)
    batteries.push(
      description: 'All Tasks',
      tasks: allTaskNames
    )

    finished = TabCAT.Encounter.getTasksFinished()

    for battery in batteries
      if not battery.description? or battery.tasks.length is 0
        continue

      $batteryDiv = $('<div></div>', class: 'battery')
      $batteryHeader = $('<div></div>', class: 'header')
      $batteryHeader.text(battery.description)
      $batteryDiv.append($batteryHeader)

      $tasksDiv = $('<div></div>', class: 'tasks collapsed')

      for taskName in battery.tasks
        task = tasksByName[taskName]

        if not (task? and task.start? and task.description?)
          continue

        $taskDiv = $('<div></div>', class: 'task')

        iconUrl = TabCAT.Console.getTaskIconUrl(task)

        if finished[taskName]
          # make the icon the background, and the checkmark the foreground
          # TODO: use absolute positioning and z-indexes to do a real overlay
          $icon = $('<img>', class: 'icon', src: 'img/check-overlay.png')
          $icon.css('background-image', "url(#{iconUrl})")
        else
          $icon = $('<img>', class: 'icon', src: iconUrl)
        $taskDiv.append($icon)

        $taskDescription = $('<span></span>', class: 'description')
        $taskDescription.text(task.description)
        $taskDiv.append($taskDescription)

        $tasksDiv.append($taskDiv)

        do -> # create a separate scope for each click handler
          startUrl = TabCAT.Console.getTaskStartUrl(task)
          if startUrl?
            $taskDiv.on('click', (event) -> window.location = startUrl)

      $batteryDiv.append($tasksDiv)
      do ($tasksDiv) ->
        $batteryHeader.on('click', (event) ->
          event.preventDefault()
          shouldOpen = ($tasksDiv).is('.collapsed')
          $('#taskList').find('div.tasks').addClass('collapsed')
          if shouldOpen
            $tasksDiv.removeClass('collapsed')
        )

      $('#taskList').append($batteryDiv)
  )


# initialization
@initPage = ->
  TabCAT.UI.requireUserAndEncounter()

  TabCAT.UI.enableFastClick()

  $(->
    TabCAT.Console.updateStatusBar()
    showTasks()
    $('#closeEncounter').on('click', ->
      window.location = 'close-encounter.html'
      return
    )
    $('#closeEncounter').removeAttr('disabled')
  )

  TabCAT.DB.startSpilledDocSync()
