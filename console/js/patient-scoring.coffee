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

ENCOUNTER_HTML = '''
<div class="encounter">
  <div class="encounterHeader">
    <span class="encounterNum"></span>
    <span class="date"></span>
  </div>
  <div class="tasks">
  </div>
</div>
'''

TASK_HTML = '''
<div class="task" id="task-12345678">
  <div class="taskHeader">
    <img class="icon">
    <span class="description"></span>
  </div>
  <div class="scores">
  </div>
</div>
'''

SCORE_HTML = '''
<div class="score">
  <div class="scoreHeader">
    <span class="description"></span>
  </div>
  <div class="scoreBody">
    <div class="rawScore">
      <p class="description">Raw Score</p>
      <p class="value"></p>
    </div>
    <div class="norms">
      <table class="norm">
        <thead>
          <tr>
            <th class="age">Age</th>
            <th class="mean">Mean</th>
            <th class="stddev">Std. Dev.</th>
            <th class="percentile">Percentile*</th>
          </tr>
        </thead>
        <tbody>
        </tbody>
      </table>
    </div>
  </div>
</div>
'''


NORM_HTML = '''
<tr>
  <td class="age"></td>
  <td class="mean"></td>
  <td class="stddev"></td>
  <td class="percentile"></td>
</tr>
'''


showScoring = ->
  $('#patientScoring').empty()

  TabCAT.Patient.getHistory().then((history) ->
    if not history?
      return

    TabCAT.Task.getBatteriesAndTasks().then((bt) ->
      tasksByName = bt.tasks
      designDocToTaskIds = {}

      for e in history.encounters by -1
        $encounter = $(ENCOUNTER_HTML)
        $encounter.attr('id', "encounter-#{e._id}")
        $encounter.find('.encounterNum').text(
          "Encounter ##{e.encounterNum + 1}")
        $encounter.find('.date').text(e.year)  # TODO: add full date

        $tasks = $encounter.find('.tasks')

        for t in e.tasks by -1
          if not t.name?
            continue

          $task = $(TASK_HTML)
          $task.attr('id', "task-#{t._id}")

          taskInfo = bt.tasks[t.name]

          if taskInfo?
            $task.find('.icon').attr(
              'src', TabCAT.Console.getTaskIconUrl(taskInfo))
            $task.find('.description').text(taskInfo.description)

            $scores = $task.find('.scores')

            if t.finishedAt?
              designDocId = taskInfo.designDocId
              designDocToTaskIds[designDocId] ?= {}
              designDocToTaskIds[designDocId][t._id] = true
              $scores.text('loading scores...')
            else
              $scores.text('task not completed')

          else
            $task.find('.icon').attr('src',
              TabCAT.Console.DEFAULT_TASK_ICON_URL)
            $task.find('.description').text("Unknown Task: #{t.name}")

          $tasks.append($task)

        $('#patientScoring').append($encounter)

      for own designDocId, taskIds of designDocToTaskIds
        do (designDocId, taskIds) ->
          TabCAT.Patient.scoreTasksFromDesignDoc(designDocId).then(
            (taskToScoring) ->
              for taskId in _.keys(taskIds)
                $scores = $("#task-#{taskId} .scores")
                $scores.empty()

                scores = taskToScoring[taskId]?.scores

                if scores?
                  for score in scores
                    $score = $(SCORE_HTML)
                    $score.find('.scoreHeader .description').text(
                      score.description)
                    $score.find('.scoreBody .rawScore .value').text(
                      score.value.toFixed(1))

                    if score.norms?
                      for norm in score.norms
                        $norm = $(NORM_HTML)

                        minAge = norm.cohort?.minAge ? 0
                        if norm.cohort?.maxAge?
                          age = minAge + '-' + norm.cohort.maxAge
                        else
                          age = minAge + '+'
                        $norm.find('.age').text(age)

                        $norm.find('.mean').text(norm.mean ? '-')
                        $norm.find('.stddev').text(norm.stddev ? '-')

                        $score.find('.scoreBody .norms tbody').append($norm)

                    $scores.append($score)
                else
                  $scores.text('no scoring available for this task')
          )
    )
  )




# initialization
@initPage = ->
  TabCAT.UI.requireUserAndEncounter()

  TabCAT.UI.enableFastClick()

  $(->
    TabCAT.Console.updateStatusBar()
    showScoring()
  )

  TabCAT.DB.startSpilledDocSync()
