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


# empty translations block for now
#translations =
#  en:
#    translation:
#  es:
#    translation:

# main div's aspect ratio (pretend we're on an iPad)
ASPECT_RATIO = 4/3

#range random digit symbol trial
DIGIT_SYMBOL_RANGE = [1..7]

#trial should last 2 minutes
MAX_DURATION = 60 * 2

DIGITS_TO_SYMBOLS = [

]

currentNumber = null

allNumbers = []

secondsElapsed = 0

numberCorrect = 0

timer = null


showStartScreen = ->
  $startScreen = $('#startScreen')

  $startScreen.find('button').on('mousedown touchstart', ->
    $startScreen.hide()
    startTimer()
  )

  $startScreen.show()

# INITIALIZATION
@initTask = ->
  TabCAT.Task.start(trackViewport: true)

  TabCAT.UI.turnOffBounce()
  TabCAT.UI.enableFastClick()

  $(->
    $task = $('#task')
    $rectangle = $('#rectangle')
    $symbols = $('.symbol')

    $symbols.on('mousedown touchstart', updateNumber)

    TabCAT.UI.requireLandscapeMode($task)
    #$task.on('mousedown touchstart', startTask)

    TabCAT.UI.fixAspectRatio($rectangle, ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)

    showStartScreen()
  )

startTask = ->
  console.log "startTask called"

updateNumber = ->
  console.log "updating number"
  currentNumber = _.sample(DIGIT_SYMBOL_RANGE)
  allNumbers.push currentNumber
  $currentNumber = $('#currentNumber')
  $currentNumber.html(currentNumber)

startTimer = ->
  console.log "starting timer"
  timer = setInterval timerMethod, 1000

timerMethod = ->
  secondsElapsed += 1
  $timer = $('#secondsElapsed')
  $timer.html(secondsElapsed + " seconds")
  if (secondsElapsed >= MAX_DURATION)
    endTask()


endTask = ->
  #end of test, display message and go back to home screen
  clearInterval timer
