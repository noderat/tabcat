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
      '...'
  es:
    translation:
      '...'

MemoryTask = class
  constructor: ->

    @CHOICES = {
      ANIMAL: {
        DOLPHIN: 'dolphin',
        WOLF: 'wolf',
        TURTLE: 'turtle',
        SHARK: 'shark',
        COW: 'cow',
        BEAR: 'bear',
        FROG: 'frog',
        SHEEP: 'sheep',
        RABBIT: 'rabbit',
        PIG: 'pig',
        WHALE: 'whale',
        GOAT: 'goat',
        MONKEY: 'monkey',
        SNAKE: 'snake',
        FOX: 'fox',
        MOUSE: 'mouse',
        TIGER: 'tiger'
      },
      FOOD: {
        APPLE: 'apple',
        POTATO: 'potato',
        GRAPES: 'grapes',
        MELON: 'melon',
        COCONUT: 'coconut',
        CHERRY: 'cherry',
        LETTUCE: 'lettuce',
        PEAS: 'peas',
        CARROT: 'carrot',
        TOMATO: 'tomato',
        MUSHROOM: 'mushroom',
        LEMON: 'lemon',
        PLUM: 'plum',
        BANANA: 'banana',
        MANGO: 'mango',
        PEPPER: 'pepper',
        SQUASH: 'squash'
      }
    }

    @PEOPLE = {
      MAN_EXAMPLE:
        IMAGE: 'man-example.jpg'
      MAN_1:
        IMAGE: 'man1.jpg'
      MAN_2:
        IMAGE: 'man2.jpg'
      MAN_3:
        IMAGE: 'man3.jpg'
      MAN_4:
        IMAGE: 'man4.jpg'
      MAN_5:
        IMAGE: 'man5.jpg'
      MAN_6:
        IMAGE: 'man6.jpg'
      MAN_7:
        IMAGE: 'man7.jpg'
      MAN_8:
        IMAGE: 'man8.jpg'
      WOMAN_EXAMPLE:
        IMAGE: 'woman-example.jpg'
      WOMAN_1:
        IMAGE: 'woman1.jpg'
      WOMAN_2:
        IMAGE: 'woman2.jpg'
      WOMAN_3:
        IMAGE: 'woman3.jpg'
      WOMAN_4:
        IMAGE: 'woman4.jpg'
      WOMAN_5:
        IMAGE: 'woman5.jpg'
      WOMAN_6:
        IMAGE: 'woman6.jpg'
      WOMAN_7:
        IMAGE: 'woman7.jpg'
      WOMAN_8:
        IMAGE: 'woman8.jpg'
    }

    #these stay the same throughout forms
    @EXAMPLE_TRIALS = [
      {
        action: 'firstExampleRemember',
        person: @PEOPLE.MAN_EXAMPLE,
        remember: 'food',
        item: @CHOICES.FOOD.APPLE
      },
      {
        action: 'exampleRemember',
        person: @PEOPLE.WOMAN_EXAMPLE ,
        remember: 'animal',
        item: @CHOICES.ANIMAL.DOLPHIN
      },
      {
        action: 'exampleRecall',
        person: @PEOPLE.MAN_EXAMPLE,
        recall: 'food'
      },
      {
        action: 'exampleRecall',
        person: @PEOPLE.WOMAN_EXAMPLE,
        recall: 'animal'
      }
    ]

    #assigning people and food/animal combinations to different forms
    @FORMS = {
      FORM_ONE:
        FIRST_EXPOSURE: [{
          person: @PEOPLE.MAN_5,
          label: 'animal',
          item: @CHOICES.ANIMAL.TURTLE
        }, {
          person: @PEOPLE.WOMAN_6,
          label: 'food',
          item: @CHOICES.FOOD.PEAS
        },{
          person: @PEOPLE.WOMAN_5,
          label: 'food',
          item: @CHOICES.FOOD.LETTUCE
        }, {
          person: @PEOPLE.MAN_6,
          label: 'animal',
          item: @CHOICES.ANIMAL.WOLF
        },{
          person: @PEOPLE.WOMAN_5,
          label: 'animal',
          item: @CHOICES.ANIMAL.SHARK
        }, {
          person: @PEOPLE.MAN_5,
          label: 'food',
          item: @CHOICES.FOOD.COCONUT
        },{
          person: @PEOPLE.MAN_6,
          label: 'food',
          item: @CHOICES.FOOD.CHERRY
        }, {
          person: @PEOPLE.WOMAN_6,
          label: 'animal',
          item: @CHOICES.ANIMAL.COW
        }],
        FIRST_RECALL: [
          { person: @PEOPLE.WOMAN_5 },
          { person: @PEOPLE.MAN_5 },
          { person: @PEOPLE.WOMAN_6 },
          { person: @PEOPLE.MAN_6 }
        ],
        SECOND_EXPOSURE: [{
          person: @PEOPLE.WOMAN_5,
          label: 'animal',
          item: @CHOICES.ANIMAL.SHARK
        },{
          person: @PEOPLE.MAN_5,
          label: 'animal',
          item: @CHOICES.ANIMAL.TURTLE
        },{
          person: @PEOPLE.WOMAN_6,
          label: 'food',
          item: @CHOICES.FOOD.PEAS
        },{
          person: @PEOPLE.MAN_6,
          label: 'food',
          item: @CHOICES.FOOD.CHERRY
        },{
          person: @PEOPLE.WOMAN_6,
          label: 'animal',
          item: @CHOICES.ANIMAL.COW
        },{
          person: @PEOPLE.WOMAN_5,
          label: 'food',
          item: @CHOICES.FOOD.LETTUCE
        }, {
          person: @PEOPLE.MAN_6,
          label: 'animal',
          item: @CHOICES.ANIMAL.WOLF
        },{
          person: @PEOPLE.MAN_5,
          label: 'food',
          item: @CHOICES.FOOD.COCONUT
        }],
        SECOND_RECALL: [
          { person: @PEOPLE.MAN_6 },
          { person: @PEOPLE.MAN_5 },
          { person: @PEOPLE.WOMAN_6 },
          { person: @PEOPLE.WOMAN_5 }
        ],
        DELAYED_RECALL: [
          { person: @PEOPLE.WOMAN_6 },
          { person: @PEOPLE.MAN_5 },
          { person: @PEOPLE.MAN_6 },
          { person: @PEOPLE.WOMAN_5 }
        ]
    }

    #can switch this later
    @currentForm = @getCurrentForm()

    @formStimuli = @FORMS[@currentForm]

    # main div's aspect ratio (pretend we're on an iPad)
    @ASPECT_RATIO = 4/3

    # time values in milliseconds
    @TIME_BETWEEN_STIMULI = 3000

    @TIME_BETWEEN_RECALL = 10000

  getCurrentForm: ->
    #static for now, will have some way of determining later
    return 'FORM_ONE'

  generateExposureStimuli: (exposureData) ->
    stimuli = []

    for data in exposureData
      do ( ->
        obj =
          action: 'rememberOne',
          person: data.person,
          type: data.label,
          item: data.item

        stimuli.push obj
      )

    return stimuli

  generateRecalls: (recallData) ->
    recalls = []
    for data in recallData
      do -> recalls.push { action: 'recallBoth', person: data.person }
    return recalls

  showNextTrial: (slide) ->
    # looking to move away from switch, will refactor later.
    # looking for something to automatically call
    # function with the same name as type, but there's some strange
    # behavior regarding scope that I don't yet understand
    switch slide.action
      when "firstExampleRemember" then \
        @firstExampleRemember slide.person, slide.item
      when "exampleRemember" then \
        @exampleRemember slide.person, slide.item
      when "exampleRecall" then \
        @exampleRecall slide.person, slide.recall
      when "rememberOne" then \
        @rememberOne slide.person, slide.item
      when "recallBoth" then \
        @recallBoth slide.person

  showRememberScreen: ->
    $("#exampleScreen").hide()
    $("#trialScreen").hide()
    $("#instructionsScreen").hide()
    $("#rememberScreen").show()
    #resume after this

  showBlankScreen: ->
    $("#exampleScreen").hide()
    $("#trialScreen").hide()
    $("#instructionsScreen").hide()
    $("#rememberScreen").hide()

  start: ->
    TabCAT.Task.start(
      i18n:
        resStore: translations
      trackViewport: true
    )
    TabCAT.UI.turnOffBounce()

    $task = $('#task')
    $rectangle = $('#rectangle')

    TabCAT.UI.requireLandscapeMode($task)
    $task.on('mousedown touchstart', ( -> ) )

    TabCAT.UI.fixAspectRatio($rectangle, @ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)

    @showStartScreen()

  firstExampleRemember: (person, item) ->
    $("#supplementaryInstruction").hide()
    $("#exampleImage img").attr('src', "img/" + person.IMAGE)
    $("#exampleFood").empty().html("<p>" + item + "</p>")
    $("#exampleScreen").show()

  exampleRemember: (person, item) ->
    $("#supplementaryInstruction").show().html(
      "<p>And her favorite animal is:</p>"
    )
    $("#exampleScreen").hide()
    $("#recallOne").hide()
    $("#recallBoth").hide()

    $("#screenImage img").attr('src', "img/" + person.IMAGE)
    $("#rememberOne").show().empty().html( \
      '<p>' + item + '</p>' )
    $("#trialScreen").show()

  exampleRecall: (person, recall) ->
    $("#supplementaryInstruction").hide()
    $("#exampleScreen").hide()
    $("#rememberOne").hide()
    $("#recallBoth").hide()

    #does nothing for now, may use to validate later
    correctAnswer = person[recall.toUpperCase()]

    $("#screenImage img").attr('src', "img/" + person.IMAGE)
    $("#recallOne").show().find(".recallLabel").empty().html(recall + ":")
    $("#trialScreen").show()

  rememberOne: (person, item) ->
    $("#recallBoth").hide()
    $("#recallOne").hide()

    $("#screenImage img").attr('src', "img/" + person.IMAGE)
    $("#rememberOne").show().empty().html(
      "<p>" + item + "</p>" )
    $("#trialScreen").show()

  recallBoth: (person) ->
    $("#exampleScreen").hide()
    $("#rememberOne").hide()
    $("#recallOne").hide()
    $("#recallBoth").hide()

    $("#screenImage img").attr('src', "img/" + person.IMAGE)
    $("#recallBoth").show()
    $("#trialScreen").show()

  endTask: ->
    TabCAT.Task.finish()

@LearningMemoryTask = class extends MemoryTask
  constructor: ->
    super()

    @currentExampleTrial = 0

  showStartScreen: ->
    $("#backButton").hide()
    @currentExampleTrial = 0

    @showNextTrial(@EXAMPLE_TRIALS[@currentExampleTrial])

    @currentExampleTrial++

    $("#nextButton").unbind().show().one('tap', =>
      @iterateExampleScreens()
    )

  iterateExampleScreens: ->

    #these should already be in this state the first time
    #but should be reset if back button was pressed from instruction screen
    $("#beginButton").hide()
    $("#nextButton").show()
    $("#backButton").show()

    @showNextTrial(@EXAMPLE_TRIALS[@currentExampleTrial])

    $("#nextButton").unbind().one('tap', (event) =>
      @currentExampleTrial++
      if @currentExampleTrial <= @EXAMPLE_TRIALS.length - 1
        @iterateExampleScreens()
      else
        @showInstructionsScreen()
      event.stopPropagation()
      return false
    )

    $("#backButton").unbind().one('tap', (event) =>
      @currentExampleTrial--
      if @currentExampleTrial == 0
        @showStartScreen()
      else
        @iterateExampleScreens()

      event.stopPropagation()
      return false
    )

  showInstructionsScreen: ->
    $("#exampleScreen").hide()
    $("#trialScreen").hide()
    $("#instructionsScreen").show()

    $("#nextButton").unbind().hide()
    $("#beginButton").unbind().show().one('tap', =>
      #start actual task
      @beginFirstExposureTrials()
    )

    $("#backButton").unbind().one('tap', =>
      @currentExampleTrial--
      $("#exampleScreen").show()
      $("#trialScreen").show()
      $("#instructionsScreen").hide()
      @iterateExampleScreens()
    )

  beginFirstExposureTrials: ->
    $("#beginButton").unbind().hide()
    $("#backButton").unbind().hide()

    @showRememberScreen()
    #generate trials for exposure
    trials = @generateExposureStimuli(@formStimuli.FIRST_EXPOSURE)
    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      $("#rememberScreen").hide()
      @iterateFirstExposureTrials(trials)
    )

  beginSecondExposureTrials: ->
    @showRememberScreen()
    #generate trials for exposure
    trials = @generateExposureStimuli(@formStimuli.SECOND_EXPOSURE)
    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      $("#rememberScreen").hide()
      @iterateSecondExposureTrials(trials)
    )

  beginFirstRecall: ->
    @showBlankScreen()

    trials = @generateRecalls(@formStimuli.FIRST_RECALL)

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      @iterateFirstRecallTrials(trials)
    )

  beginSecondRecall: ->
    @showBlankScreen()

    trials = @generateRecalls(@formStimuli.SECOND_RECALL)

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      @iterateSecondRecallTrials(trials)
    )

  iterateFirstRecallTrials: (trials) ->

    @showNextTrial(trials.shift())

    $(".nextButton").one("tap", =>
      if trials.length
        @iterateFirstRecallTrials(trials)
      else
        @beginSecondExposureTrials()
    )

  iterateSecondRecallTrials: (trials) ->

    @showNextTrial(trials.shift())

    $(".nextButton").one("tap", =>
      if trials.length
        @iterateSecondRecallTrials(trials)
      else
        @endTask()
    )

  iterateFirstExposureTrials: (trials) ->
    @showNextTrial(trials.shift())

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      if trials.length
        @iterateFirstExposureTrials(trials)
      else
        @beginFirstRecall()
    )

  iterateSecondExposureTrials: (trials) ->
    @showNextTrial(trials.shift())

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      if trials.length
        @iterateSecondExposureTrials(trials)
      else
        @beginSecondRecall()
    )

#Not implementing for now, just creating the skeleton
@DelayMemoryTask = class extends MemoryTask
  constructor: ->
    super()

  showStartScreen: ->
    @beginDelayedRecall()

  beginDelayedRecall: ->
    trials = @generateRecalls(@formStimuli.DELAYED_RECALL)

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      @iterateDelayedRecallTrials(trials)
    )

  iterateDelayedRecallTrials: (trials) ->

    @showNextTrial(trials.shift())

    $(".nextButton").one("tap", =>
      if trials.length
        @iterateDelayedRecallTrials(trials)
      else
        @endTask()
    )