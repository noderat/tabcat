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
  CHOICES = {
    ANIMAL: {
      DOLPHIN: 'dolphin',
      WOLF: 'wolf',
      TURTLE: 'turtle',
      SHARK: 'shark',
      COW: 'cow'
    },
    FOOD: {
      APPLE: 'apple',
      POTATO: 'potato',
      GRAPES: 'grapes',
      MELON: 'melon',
      CARROTS: 'carrots'
    }
  }

  PEOPLE = {
    MAN1: { #glasses and red shirt
      FOOD: CHOICES.FOOD.APPLE,
      IMAGE: 'man1'
    },
    MAN2: { #bald with sport coat
      FOOD: CHOICES.FOOD.POTATO,
      ANIMAL: CHOICES.ANIMAL.TURTLE,
      IMAGE: 'man2'
    },
    MAN3: { #purple shirt
      FOOD: CHOICES.FOOD.MELON,
      ANIMAL: CHOICES.ANIMAL.COW,
      IMAGE: 'man3'
    },
    WOMAN1: { #long dark hair
      ANIMAL: CHOICES.ANIMAL.DOLPHIN,
      IMAGE: 'woman1'
    },
    WOMAN2: { #hair pullled back with blue eyes
      FOOD: CHOICES.FOOD.CARROTS,
      ANIMAL: CHOICES.ANIMAL.WOLF,
      IMAGE: 'woman2'
    },
    WOMAN3: { #glasses and gray hair
      FOOD: CHOICES.FOOD.GRAPES,
      ANIMAL: CHOICES.ANIMAL.SHARK,
      IMAGE: 'woman3'
    }
  }

  FORM_ONE = {
    EXAMPLE: [
      { type: 'firstExampleRemember', person: PEOPLE.MAN1, remember: 'food' },
      { type: 'exampleRemember', person: PEOPLE.WOMAN1 , remember: 'animal' },
      { type: 'exampleRecall', person: PEOPLE.MAN1, recall: 'food' },
      { type: 'exampleRecall', person: PEOPLE.WOMAN1, recall: 'animal' }
    ],
    TRIALS: {
      IMMEDIATE_RECALL: {
        REMEMBER: [
          { type: 'rememberOne', person: PEOPLE.MAN2, remember: 'food' },
          { type: 'rememberOne', person: PEOPLE.WOMAN2, remember: 'animal' },
          { type: 'rememberOne', person: PEOPLE.WOMAN3, remember: 'food' },
          { type: 'rememberOne', person: PEOPLE.MAN2, remember: 'animal' },
          { type: 'rememberOne', person: PEOPLE.MAN3, remember: 'food' },
          { type: 'rememberOne', person: PEOPLE.WOMAN3, remember: 'animal' },
          { type: 'rememberOne', person: PEOPLE.MAN3, remember: 'animal' },
          { type: 'rememberOne', person: PEOPLE.WOMAN2, remember: 'food' }
        ],
        RECALL: [
          { type: 'recallTwo', person: PEOPLE.MAN2 },
          { type: 'recallTwo', person: PEOPLE.WOMAN3 },
          { type: 'recallTwo', person: PEOPLE.WOMAN2 },
          { type: 'recallTwo', person: PEOPLE.MAN3 }
        ]
      },
      DELAYED_RECALL: {
        REMEMBER: [
          {type: 'rememberOne', person: PEOPLE.WOMAN2, remember: 'animal'},
          {type: 'rememberOne', person: PEOPLE.MAN2, remember: 'food'},
          {type: 'rememberOne', person: PEOPLE.WOMAN3, remember: 'animal'},
          {type: 'rememberOne', person: PEOPLE.MAN2, remember: 'animal'},
          {type: 'rememberOne', person: PEOPLE.WOMAN2, remember: 'food'},
          {type: 'rememberOne', person: PEOPLE.MAN3, remember: 'animal'},
          {type: 'rememberOne', person: PEOPLE.WOMAN3, remember: 'food'},
          {type: 'rememberOne', person: PEOPLE.MAN3, remember: 'food'}
        ],
        RECALL: [
          {type: 'recallTwo', person: PEOPLE.MAN3},
          {type: 'recallTwo', person: PEOPLE.MAN2},
          {type: 'recallTwo', person: PEOPLE.WOMAN3},
          {type: 'recallTwo', person: PEOPLE.WOMAN2}
        ]
      }
    }
  }
  # main div's aspect ratio (pretend we're on an iPad)
  ASPECT_RATIO = 4/3

  constructor: ->
    #current form - static for now, will add switch later
    #@currentForm = FORM_ORDER.FORM_ONE
    #@currentFormNumber = 1

    #current digit presented on screen
    @currentStimuli = null

    @secondsElapsed = 0

    @isInDebugMode = TabCAT.Task.isInDebugMode()

    @practiceTrialsShown = 0

    #can switch this later
    @currentForm = FORM_ONE

  showStartScreen: ->

    @showNextTrial(@currentForm.EXAMPLE)

    $("#task").on('tap', =>
      if @currentForm.EXAMPLE.length
        @showNextTrial(@currentForm.EXAMPLE)
      else
        @showInstructionsScreen()
    )

  showNextTrial: (slides) ->

    nextSlide = slides.shift()
    # looking to move away from switch, will refactor later.
    # looking for something to automatically call
    # function with the same name as type, but there's some strange
    # behavior regarding scope that I don't yet understand
    switch nextSlide.type
      when "firstExampleRemember" then \
        @firstExampleRemember nextSlide.person, nextSlide.remember
      when "exampleRemember" then \
        @exampleRemember nextSlide.person, nextSlide.remember
      when "exampleRecall" then \
        @exampleRecall nextSlide.person, nextSlide.recall
      when "rememberOne" then \
        @rememberOne nextSlide.person, nextSlide.remember
      when "recallTwo" then \
        @recallTwo nextSlide.person
      else console.log "some other type"

  showInstructionsScreen: ->
    $("#task").unbind()
    $("#exampleScreen").hide()
    $("#trialScreen").hide()
    $("#instructionsScreen").show()

    $("#task").one('tap', =>
      @beginTrials(@currentForm)
    )

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

  beginTrials: (form) ->
    @showRememberScreen()
    $("#task").unbind().on('tap', (event) =>
      $("#rememberScreen").hide()
      if form.TRIALS.IMMEDIATE_RECALL.REMEMBER.length
        @showNextTrial(form.TRIALS.IMMEDIATE_RECALL.REMEMBER)
      else
        @beginRecall(form)
      event.stopPropagation()
      return false
    )

  beginRecall: (form) ->
    @showBlankScreen()

    $("#task").unbind().on('tap', =>
      $("#rememberScreen").hide()

      if form.TRIALS.IMMEDIATE_RECALL.RECALL.length
        @showNextTrial(form.TRIALS.IMMEDIATE_RECALL.RECALL)
      else
        $("#task").unbind()
        console.log "out of recalls"
    )

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

    TabCAT.UI.fixAspectRatio($rectangle, ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)

    @showStartScreen()

  firstExampleRemember: (person, remember) ->
    $("#exampleImage img").attr('src', "img/" + person.IMAGE + ".jpg")
    $("#exampleFood").empty().html("<p>" + person.FOOD + "</p>")
    $("#exampleScreen").show()

  exampleRemember: (person, remember) ->
    $("#exampleScreen").hide()
    $("#recallOne").hide()
    $("#recallBoth").hide()

    $("#screenImage img").attr('src', "img/" + person.IMAGE + ".jpg")
    $("#rememberOne").show().empty().html( \
      "<p>" + person[remember.toUpperCase()] + "</p>" )
    $("#trialScreen").show()

  exampleRecall: (person, recall) ->
    $("#exampleScreen").hide()
    $("#rememberOne").hide()
    $("#recallBoth").hide()

    #does nothing for now, may use to validate later
    correctAnswer = person[recall.toUpperCase()]

    $("#screenImage img").attr('src', "img/" + person.IMAGE + ".jpg")
    $("#recallOne").show().find(".recallLabel").empty().html(recall + ":")
    $("#trialScreen").show()

  rememberOne: (person, remember) ->
    $("#recallBoth").hide()
    $("#recallOne").hide()

    $("#screenImage img").attr('src', "img/" + person.IMAGE + ".jpg")
    $("#rememberOne").show().empty().html(
      "<p>" + person[remember.toUpperCase()] + "</p>" )
    $("#trialScreen").show()

  recallTwo: (person) ->
    $("#exampleScreen").hide()
    $("#rememberOne").hide()
    $("#recallOne").hide()
    $("#recallBoth").hide()

    $("#screenImage img").attr('src', "img/" + person.IMAGE + ".jpg")
    $("#recallBoth").show()
    $("#trialScreen").show()


@InitialMemoryTask = class extends MemoryTask
  constructor: ->
    super()

#Not implementing for now, just creating the skeleton
@DelayedRecallTask = class extends MemoryTask
