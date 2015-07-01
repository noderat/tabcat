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
translations =
  en:
    translation:
      start_screen_html:
        1: 'Look at the boxes above.'
        2: 'Each has a number in the upper part and a picture <br> in the ' +
           'lower part.  Each number has its own picture.'
        3: 'Now look at the pictures below.  <br>They match ' +
           'the pictures above.'
      start_screen_next_html:
        1: 'Each time you see a number in the middle of the screen, ' +
           'look to see which picture matches the number above, ' +
           'and touch that picture below.'

@DigitSymbolTask = class

  # main div's aspect ratio (pretend we're on an iPad)
  ASPECT_RATIO = 4/3

  #range random digit symbol trial
  DIGIT_SYMBOL_RANGE = [1..7]

  #trial should last 2 minutes
  MAX_DURATION = 60 * 2

  #after choice is selected
  FADEOUT_DURATION = 700

  #fading to new number
  FADEIN_DURATION = 500

  PRACTICE_TRIALS = 4

  #references and descriptions of symbols
  SYMBOLS =
    TRI_BLOCKS:
      image_number: 1
      description: "Three blocks oriented in a square"
    INNER_CIRCLES:
      image_number: 2
      description: "Two circles, one filled, inside larger circle"
    TRI_CIRCLES:
      image_number: 3
      description: "Three connected circles, one filled"
    MOUSTACHE:
      image_number: 4
      description: "Two spirals connected by line, resembles moustache"
    TEARDROPS:
      image_number: 5
      description: "Two teardrops arranged in various ways"
    MOBIUS:
      image_number: 6
      description: "A filled 2D mobius"
    DIAMOND:
      image_number: 7
      description: "Half-filled diamond"

  #all that needs to be done to create other forms
  #is to upload the images for them and add FORM_TWO, etc
  #with the same ICON_BAR and SYMBOL_BAR arrays
  #with references to the symbols in the order they should appear
  FORM_ORDER =
    FORM_ONE:
      ICON_BAR: [
        SYMBOLS.TRI_BLOCKS
        SYMBOLS.INNER_CIRCLES
        SYMBOLS.TEARDROPS
        SYMBOLS.TRI_CIRCLES
        SYMBOLS.MOBIUS
        SYMBOLS.DIAMOND
        SYMBOLS.MOUSTACHE
      ]
      SYMBOL_BAR: [
        { relativeSequence: 3, symbol: SYMBOLS.TEARDROPS }
        { relativeSequence: 7, symbol: SYMBOLS.MOUSTACHE }
        { relativeSequence: 4, symbol: SYMBOLS.TRI_CIRCLES }
        { relativeSequence: 1, symbol: SYMBOLS.TRI_BLOCKS }
        { relativeSequence: 6, symbol: SYMBOLS.DIAMOND }
        { relativeSequence: 5, symbol: SYMBOLS.MOBIUS }
        { relativeSequence: 3, symbol: SYMBOLS.INNER_CIRCLES }
      ]

  constructor: ->
    #current form - static for now, will add switch later
    @currentForm = FORM_ORDER.FORM_ONE
    @currentFormNumber = 1

    #current digit presented on screen
    @currentStimuli = null

    #array of all numbers presented in task
    @allNumbers = []

    @secondsElapsed = 0

    @numberCorrect = 0

    #contains the timer to keep track of progress
    @timer = null

    @$startScreen = $('#startScreen')

    @isInDebugMode = TabCAT.Task.isInDebugMode()


  showStartScreen: ->
    @$startScreen.on('mousedown touchstart', ( ->
      @startScreenNext()
    ).bind(this))

    instructions = $.t('start_screen_html', {returnObjectTrees: true})
    html = _.map(instructions, (value, key) ->
      '<p>' + value + '</p>') \
      .join('')

    @$startScreen.append html

    @$startScreen.show()

  startScreenNext: ->
    instructions = $.t('start_screen_next_html', {returnObjectTrees: true})
    html = _.map(instructions, (value, key) ->
      '<p>' + value + '</p>')
    .join('')

    @$startScreen.empty().append html

    $currentStimuli = $('#currentStimuli')
    $currentStimuli.html 7

    @$startScreen.on('mousedown touchstart', ( ->
      @$startScreen.hide()
      @startTimer()
      @updatecurrentStimuli()
    ).bind(this))


  # INITIALIZATION
  initTask: ->
    TabCAT.Task.start(
      i18n:
        resStore: translations
      trackViewport: true
    )

    TabCAT.UI.turnOffBounce()
    TabCAT.UI.enableFastClick()

    #draw top row of digits and symbols
    for element, index in @currentForm.ICON_BAR
      $icon = $('#iconSymbol' + (index + 1))
      $icon.find('.digitSymbolNumber').html(index + 1)
      $icon.find('img').attr('src', 'img/' + \
        element.image_number + '.' + @currentFormNumber + '.png')

    #draw bottom row of digits and symbols
    for element, index in @currentForm.SYMBOL_BAR
      $symbol = $('#symbol' + (index + 1))
      $symbol.find('img').attr('src', 'img/' + \
        element.symbol.image_number + '.' + @currentFormNumber + '.png') \
          .attr('data-sequence', element.relativeSequence)

    $task = $('#task')
    $rectangle = $('#rectangle')
    $symbols = $('.symbol')

    $symbols.on('mousedown touchstart', @handleSymbolTouch.bind(this))

    TabCAT.UI.requireLandscapeMode($task)

    TabCAT.UI.fixAspectRatio($rectangle, ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)

    @showStartScreen()

  handleSymbolTouch: (event) ->

    correct = false
    if @currentStimuli == $(event.target).data('sequence')
      #need to log correct event
      @numberCorrect++
      correct = true
    if @isInDebugMode
      @updateDebugInfo()
    @updatecurrentStimuli()

    interpretation =
      correct: correct
    console.log @getTaskState()
    console.log event
    console.log interpretation
    TabCAT.Task.logEvent(@getTaskState(), event, interpretation)

  updatecurrentStimuli: ->
    @currentStimuli = @getNewStimuli()
    @allNumbers.push @currentStimuli
    $currentStimuli = $('#currentStimuli')
    $.when($currentStimuli.fadeOut FADEOUT_DURATION ).then( (->
      $currentStimuli.html @currentStimuli
      $currentStimuli.fadeIn FADEIN_DURATION
    ).bind(this))

  getNewStimuli: ->
    newStimuli = _.sample DIGIT_SYMBOL_RANGE
    if newStimuli == @currentStimuli then @getNewStimuli() else newStimuli

  startTimer: ->
    @timer = setInterval @taskTimer.bind(this), 1000

  taskTimer: ->
    @secondsElapsed += 1
    if @isInDebugMode == true
      $timer = $('#secondsElapsed')
      $timer.html(@secondsElapsed + " seconds")
    if (@secondsElapsed >= MAX_DURATION)
      @endTask()

  endTask: ->
    #end of test, display message and go back to home screen
    console.log @numberCorrect
    clearInterval @timer

  updateDebugInfo: ->
    $('#numberCorrect').html "Correct: " + @numberCorrect
    $('#totalShown').html "Total: " + @allNumbers.length

  getTaskState: ->
    state =
      numberCorrect: @numberCorrect
      stimuli: @currentStimuli
      trialNum: @allNumbers.length

    if @inPracticeMode
      state.practiceMode = true

    return state

  inPracticeMode: ->
    false #no practice mode for now