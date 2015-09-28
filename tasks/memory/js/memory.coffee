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
        KEY: 'man-example'
        IMAGE: 'man-example.jpg'
      MAN_1:
        KEY: 'man1'
        IMAGE: 'man1.jpg'
        FOOD: @CHOICES.FOOD.MELON
        ANIMAL: @CHOICES.ANIMAL.RABBIT
      MAN_2:
        KEY: 'man2'
        IMAGE: 'man2.jpg'
        FOOD: @CHOICES.FOOD.POTATO
        ANIMAL: @CHOICES.ANIMAL.FROG
      MAN_3:
        KEY: 'man3'
        IMAGE: 'man3.jpg'
        FOOD: @CHOICES.FOOD.PLUM
        ANIMAL: @CHOICES.ANIMAL.PIG
      MAN_4:
        KEY: 'man4'
        IMAGE: 'man4.jpg'
        FOOD: @CHOICES.FOOD.MUSHROOM
        ANIMAL: @CHOICES.ANIMAL.WHALE
      MAN_5:
        KEY: 'man5'
        IMAGE: 'man5.jpg'
        FOOD: @CHOICES.FOOD.COCONUT
        ANIMAL: @CHOICES.ANIMAL.TURTLE
      MAN_6:
        KEY: 'man6'
        IMAGE: 'man6.jpg'
        FOOD: @CHOICES.FOOD.CHERRY
        ANIMAL: @CHOICES.ANIMAL.WOLF
      MAN_7:
        KEY: 'man7'
        IMAGE: 'man7.jpg'
        FOOD: @CHOICES.FOOD.BANANA
        ANIMAL: @CHOICES.ANIMAL.FOX
      MAN_8:
        KEY: 'man8'
        IMAGE: 'man8.jpg'
        FOOD: @CHOICES.FOOD.SQUASH
        ANIMAL: @CHOICES.ANIMAL.SNAKE
      WOMAN_EXAMPLE:
        KEY: 'woman-example'
        IMAGE: 'woman-example.jpg'
      WOMAN_1:
        KEY: 'woman1'
        IMAGE: 'woman1.jpg'
        FOOD: @CHOICES.FOOD.GRAPES
        ANIMAL: @CHOICES.ANIMAL.SHEEP
      WOMAN_2:
        KEY: 'woman2'
        IMAGE: 'woman2.jpg'
        FOOD: @CHOICES.FOOD.CARROT
        ANIMAL: @CHOICES.ANIMAL.BEAR
      WOMAN_3:
        KEY: 'woman3'
        IMAGE: 'woman3.jpg'
        FOOD: @CHOICES.FOOD.TOMATO
        ANIMAL: @CHOICES.ANIMAL.GOAT
      WOMAN_4:
        KEY: 'woman4'
        IMAGE: 'woman4.jpg'
        FOOD: @CHOICES.FOOD.LEMON
        ANIMAL: @CHOICES.ANIMAL.MONKEY
      WOMAN_5:
        KEY: 'woman5'
        IMAGE: 'woman5.jpg'
        FOOD: @CHOICES.FOOD.LETTUCE
        ANIMAL: @CHOICES.ANIMAL.SHARK
      WOMAN_6:
        KEY: 'woman6'
        IMAGE: 'woman6.jpg'
        FOOD: @CHOICES.FOOD.PEAS
        ANIMAL: @CHOICES.ANIMAL.COW
      WOMAN_7:
        KEY: 'woman7'
        IMAGE: 'woman7.jpg'
        FOOD: @CHOICES.FOOD.PEPPER
        ANIMAL: @CHOICES.ANIMAL.TIGER
      WOMAN_8:
        KEY: 'woman8'
        IMAGE: 'woman8.jpg'
        FOOD: @CHOICES.FOOD.MANGO
        ANIMAL: @CHOICES.ANIMAL.MOUSE
    }

    @EXAMPLE_PEOPLE = [
      @PEOPLE.WOMAN_EXAMPLE,
      @PEOPLE.MAN_EXAMPLE
    ]

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
        PEOPLE: [
          @PEOPLE.MAN_5,
          @PEOPLE.MAN_6,
          @PEOPLE.WOMAN_5,
          @PEOPLE.WOMAN_6
        ]
        FIRST_EXPOSURE: [
          { person: @PEOPLE.MAN_5, item: 'animal' },
          { person: @PEOPLE.WOMAN_6, item: 'food' },
          { person: @PEOPLE.WOMAN_5, item: 'food' },
          { person: @PEOPLE.MAN_6, item: 'animal' },
          { person: @PEOPLE.WOMAN_5, item: 'animal'},
          { person: @PEOPLE.MAN_5, item: 'food' },
          { person: @PEOPLE.MAN_6, item: 'food' },
          { person: @PEOPLE.WOMAN_6, item: 'animal'}
        ],
        FIRST_RECALL: [
          { person: @PEOPLE.WOMAN_5 },
          { person: @PEOPLE.MAN_5 },
          { person: @PEOPLE.WOMAN_6 },
          { person: @PEOPLE.MAN_6 }
        ],
        SECOND_EXPOSURE: [
          { person: @PEOPLE.WOMAN_5, item: 'animal' },
          { person: @PEOPLE.MAN_5, item: 'animal' },
          { person: @PEOPLE.WOMAN_6, item: 'food' },
          { person: @PEOPLE.MAN_6, item: 'food' },
          { person: @PEOPLE.WOMAN_6, item: 'animal' },
          { person: @PEOPLE.WOMAN_5, item: 'food'},
          { person: @PEOPLE.MAN_6, item: 'animal'},
          { person: @PEOPLE.MAN_5, item: 'food'}
        ],
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
      FORM_TWO:
        PEOPLE: [
          @PEOPLE.MAN_1,
          @PEOPLE.MAN_2,
          @PEOPLE.WOMAN_1,
          @PEOPLE.WOMAN_2
        ]
        FIRST_EXPOSURE: [
          { person: @PEOPLE.WOMAN_1, item: 'animal'},
          { person: @PEOPLE.WOMAN_2, item: 'food' },
          { person: @PEOPLE.MAN_2, item: 'animal' },
          { person: @PEOPLE.WOMAN_1, item: 'food'},
          { person: @PEOPLE.MAN_1, item: 'animal' },
          { person: @PEOPLE.MAN_2, item: 'food' },
          { person: @PEOPLE.WOMAN_2, item: 'animal' },
          { person: @PEOPLE.MAN_1, item: 'food' }
        ],
        FIRST_RECALL: [
          { person: @PEOPLE.WOMAN_1 },
          { person: @PEOPLE.MAN_2 },
          { person: @PEOPLE.WOMAN_2 },
          { person: @PEOPLE.MAN_1 }
        ],
        SECOND_EXPOSURE: [
          { person: @PEOPLE.MAN_2, item: 'animal' },
          { person: @PEOPLE.WOMAN_1, item: 'food' },
          { person: @PEOPLE.MAN_1, item: 'food' },
          { person: @PEOPLE.WOMAN_2, item: 'food' },
          { person: @PEOPLE.WOMAN_1, item: 'animal' },
          { person: @PEOPLE.MAN_1, item: 'animal' },
          { person: @PEOPLE.MAN_2, item: 'food' },
          { person: @PEOPLE.WOMAN_2, item: 'animal' }
        ],
        SECOND_RECALL: [
          { person: @PEOPLE.MAN_2 },
          { person: @PEOPLE.WOMAN_1 },
          { person: @PEOPLE.WOMAN_2 },
          { person: @PEOPLE.MAN_1 }
        ],
        DELAYED_RECALL: [
          { person: @PEOPLE.WOMAN_2 },
          { person: @PEOPLE.MAN_1 },
          { person: @PEOPLE.WOMAN_1 },
          { person: @PEOPLE.MAN_2 }
        ]
      FORM_THREE:
        PEOPLE: [
          @PEOPLE.MAN_3,
          @PEOPLE.MAN_4,
          @PEOPLE.WOMAN_3,
          @PEOPLE.WOMAN_4
        ]
        FIRST_EXPOSURE: [
          { person: @PEOPLE.MAN_3, item: 'animal' },
          { person: @PEOPLE.WOMAN_3, item: 'food' },
          { person: @PEOPLE.MAN_4, item: 'animal' },
          { person: @PEOPLE.WOMAN_4, item: 'animal' },
          { person: @PEOPLE.WOMAN_3, item: 'animal' },
          { person: @PEOPLE.WOMAN_4, item: 'food' },
          { person: @PEOPLE.MAN_3, item: 'food' },
          { person: @PEOPLE.MAN_4, item: 'food'}
        ],
        FIRST_RECALL: [
          { person: @PEOPLE.WOMAN_3 },
          { person: @PEOPLE.MAN_3 },
          { person: @PEOPLE.MAN_4 },
          { person: @PEOPLE.WOMAN_4 }
        ],
        SECOND_EXPOSURE: [
          { person: @PEOPLE.MAN_4, item: 'animal' },
          { person: @PEOPLE.WOMAN_4, item: 'animal' },
          { person: @PEOPLE.WOMAN_3, item: 'animal' },
          { person: @PEOPLE.MAN_4, item: 'food' },
          { person: @PEOPLE.MAN_3, item: 'food' },
          { person: @PEOPLE.WOMAN_3, item: 'food' },
          { person: @PEOPLE.WOMAN_4, item: 'food' },
          { person: @PEOPLE.MAN_3, item: 'animal'}
        ],
        SECOND_RECALL: [
          { person: @PEOPLE.MAN_3 },
          { person: @PEOPLE.WOMAN_3 },
          { person: @PEOPLE.MAN_4 },
          { person: @PEOPLE.WOMAN_4 }
        ],
        DELAYED_RECALL: [
          { person: @PEOPLE.WOMAN_4 },
          { person: @PEOPLE.MAN_4 },
          { person: @PEOPLE.WOMAN_3 },
          { person: @PEOPLE.MAN_3 }
        ]
      FORM_FOUR:
        PEOPLE: [
          @PEOPLE.MAN_7,
          @PEOPLE.MAN_8,
          @PEOPLE.WOMAN_7,
          @PEOPLE.WOMAN_8
        ]
        FIRST_EXPOSURE: [
          { person: @PEOPLE.WOMAN_7, item: 'food' },
          { person: @PEOPLE.MAN_8, item: 'animal' },
          { person: @PEOPLE.WOMAN_8, item: 'food' },
          { person: @PEOPLE.MAN_7, item: 'animal' },
          { person: @PEOPLE.WOMAN_7, item: 'animal' },
          { person: @PEOPLE.MAN_7, item: 'food' },
          { person: @PEOPLE.WOMAN_8, item: 'animal' },
          { person: @PEOPLE.MAN_8, item: 'food'}
        ],
        FIRST_RECALL: [
          { person: @PEOPLE.WOMAN_7 },
          { person: @PEOPLE.MAN_8 },
          { person: @PEOPLE.WOMAN_8 },
          { person: @PEOPLE.MAN_7 }
        ],
        SECOND_EXPOSURE: [
          { person: @PEOPLE.WOMAN_8, item: 'animal' },
          { person: @PEOPLE.MAN_7, item: 'animal' },
          { person: @PEOPLE.WOMAN_7, item: 'animal' },
          { person: @PEOPLE.WOMAN_8, item: 'food' },
          { person: @PEOPLE.MAN_8, item: 'food' },
          { person: @PEOPLE.WOMAN_7, item: 'food' },
          { person: @PEOPLE.MAN_8, item: 'animal' },
          { person: @PEOPLE.MAN_7, item: 'food'}
        ]
        SECOND_RECALL: [
          { person: @PEOPLE.WOMAN_8 },
          { person: @PEOPLE.MAN_8 },
          { person: @PEOPLE.MAN_7 },
          { person: @PEOPLE.WOMAN_7 }
        ],
        DELAYED_RECALL: [
          { person: @PEOPLE.MAN_7 },
          { person: @PEOPLE.WOMAN_7 },
          { person: @PEOPLE.MAN_8 },
          { person: @PEOPLE.WOMAN_8 }
        ]
    }

    [@currentForm, @currentFormNumber, @currentFormLabel] = @getCurrentForm()

    @scores = {}

    # main div's aspect ratio (pretend we're on an iPad)
    @ASPECT_RATIO = 4/3

    # time values in milliseconds
    @TIME_BETWEEN_STIMULI = 3000

    @FADE_IN_TIME = 1000

    @FADE_OUT_TIME = 1000

  #returns a tuple
  getCurrentForm: ->
    form = TabCAT.UI.getQueryString 'form'
    #there's likely a much more efficient way to do this
    #note that forms 3 and 4 do not currently exist yet
    switch form
      when "one" then return [@FORMS.FORM_ONE, 1, 'A']
      when "two" then return [@FORMS.FORM_TWO, 2, 'B']
      when "three" then return [@FORMS.FORM_THREE, 3, 'C']
      when "four" then return [@FORMS.FORM_FOUR, 4, 'D']
    #if no form found, just return default form
    return [@FORMS.FORM_ONE, 1, 'A']

  buildScoringSheetsData: (currentForm) ->
    #we can derive the people and the list of total food
    #directly from each of the forms
    people = currentForm.FIRST_RECALL
    food = []
    animals = []
    for person in people
      do ( ->
        food.push(person.person.FOOD)
        animals.push(person.person.ANIMAL)
      )

    food = food.concat(["other", "don't know"])
    animals = animals.concat(["other", "don't know"])

    sheets =
      people: people
      food: food
      animals: animals

    return sheets

  generateExposureStimuli: (exposureData) ->
    stimuli = []

    for data in exposureData
      do ( ->
        obj =
          action: 'rememberOne',
          person: data.person,
          item: data.item

        stimuli.push obj
      )

    return stimuli

  generateRecalls: (recallData) ->

    recalls = new Array()
    for data in recallData
      do ( ->
        obj = { action: 'recallBoth', person: data.person }
        recalls.push obj
      )
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

    TabCAT.UI.fixAspectRatio($rectangle, @ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)

    @showStartScreen()


  preloadEncounterImageData: (parentElement, sourcePeople) ->
    for person in sourcePeople
      do =>
        $image = @buildFaceElement(person, 'encounterFace')
        parentElement.append($image)

  preloadScoringImageData: (recalls) ->
    for containerName, recall of recalls
      do =>
        personContainerClasses = @getPersonContainerClasses()
        for person in recall
          do =>
            $image = @buildFaceElement(person.person, 'scoringFace')
            personContainerClass = personContainerClasses.shift()
            $container = $("#" + containerName + " ." + personContainerClass)
            $container.find('.scoringImage').append($image)
            $food = @buildFoodOptions(person.person.FOOD)
            $animal = @buildAnimalOptions(person.person.ANIMAL)
            $container.find('.scoringFood').append($food)
            $container.find('.scoringAnimal').append($animal)

  getPersonContainerClasses: ->
    ['personOne', 'personTwo', 'personThree', 'personFour']

  buildFaceElement: (person, className) ->
    $image = $('<img>')
      .attr( 'src', "img/" + person.IMAGE )
      .attr('data-person', person.KEY)
    if className
      $image.addClass(className)
    return $image

  buildFoodOptions: (correctFood) ->
    data = @buildScoringSheetsData(@currentForm)

    $food = $('<ul></ul>').addClass('foodSelection')
    for food in data.food
      do =>
        $li = $('<li></li>')
        if food == correctFood
          $li.addClass('correctFood')
        $li.html(food)
        $food.append($li)

    return $food

  buildAnimalOptions: (correctAnimal) ->
    data = @buildScoringSheetsData(@currentForm)

    $animal = $('<ul></ul>').addClass('animalSelection')
    for animal in data.animals
      do =>
        $li = $('<li></li>')
        if animal == correctAnimal
          $li.addClass('correctAnimal')
        $li.html(animal)
        $animal.append($li)

    return $animal

  firstExampleRemember: (person, item) ->
    $(".encounterFace").hide()
    $("#supplementaryInstruction").hide()
    $("#exampleImage img").attr('src', "img/" + person.IMAGE).show()
    $("#exampleFood").empty().html("<p>" + item + "</p>")
    $("#exampleScreen").show()

  exampleRemember: (person, item) ->
    $("#supplementaryInstruction").show().html(
      "<p>And her favorite animal is:</p>"
    )
    $("#exampleScreen").hide()
    $("#recallOne").hide()
    $("#recallBoth").hide()

    @showPerson(person)
    $("#rememberOne").show().empty().html( \
      '<p>' + item + '</p>' )
    $("#trialScreen").show()

  showPerson: (person, fadeIn = false) ->
    $(".encounterFace").hide()
    $image = $(".encounterFace[data-person='" + person.KEY + "']")
    if fadeIn
      $image.fadeIn(@FADE_IN_TIME)
    else
      $image.show()

  exampleRecall: (person, recall) ->
    $("#supplementaryInstruction").hide()
    $("#exampleScreen").hide()
    $("#rememberOne").hide()
    $("#recallBoth").hide()

    #does nothing for now, may use to validate later
    correctAnswer = person[recall.toUpperCase()]

    @showPerson(person)

    $("#recallOne").show().find(".recallLabel").empty().html(recall + ":")
    $("#trialScreen").show()

  rememberOne: (person, item) ->
    stimuli = person[item.toUpperCase()]
    $("#recallBoth").hide()
    $("#recallOne").hide()

    @showPerson(person, true)
    $("#rememberOne").empty().html(
      "<p>" + stimuli + "</p>" ).fadeIn(@FADE_IN_TIME)
    $("#trialScreen").show()

  recallBoth: (person) ->
    $("#exampleScreen").hide()
    $("#rememberOne").hide()
    $("#recallOne").hide()
    $("#recallBoth").hide()

    @showPerson(person)
    $("#recallBoth").show()
    $("#trialScreen").show()

  scoringTouchHandler: (event, type) ->
    #default to animalSelection
    className = '.foodSelection'
    parentClass = '.scoringFood'
    if type == 'animal'
      className = '.animalSelection'
      parentClass = '.scoringAnimal'

    target = event.target
    $scoringSheet = $(target).parent('.scoringFood').find('ul' + className)
    $scoringSheet.fadeIn(500)
    $scoringSheet.touchdown( =>
      $scoringSheet.fadeOut(500)
    )

  endTask: ->

    #there is currently no real event data since
    #this is more of an examiner task
    TabCAT.Task.logEvent(state, null, interpretation)

    TabCAT.Task.finish()

@LearningMemoryTask = class extends MemoryTask
  constructor: ->
    super()

    @scoringSheets = [{
      label: "Recall One"
      data: @buildScoringSheetsData(@currentForm)
    },{
      label: "Recall Two"
      data: @buildScoringSheetsData(@currentForm)
    }]

    @currentExampleTrial = 0

    @currentScoringSheet = 0

    @state = @buildInitialState()

    #generate pre-loaded images to switch out on the fly
    #concat'ing examples for first trials to work with same html
    encounterPeople = @EXAMPLE_PEOPLE.concat(@currentForm.PEOPLE)

    @preloadEncounterImageData($("#screenImage"), encounterPeople)
    @preloadScoringImageData(
      recallOneScoringScreen: @currentForm.FIRST_RECALL
      recallTwoScoringScreen: @currentForm.SECOND_RECALL
    )

  #use existing form as a template for data
  buildInitialState: ->
    return {
      RECALL_ONE: @currentForm.FIRST_RECALL
      RECALL_TWO: @currentForm.SECOND_RECALL
    }

  showStartScreen: ->
    $("#backButton").hide()
    @currentExampleTrial = 0

    @showNextTrial(@EXAMPLE_TRIALS[@currentExampleTrial])

    @currentExampleTrial++

    $("#nextButton").unbind().show().touchdown( =>
      @iterateExampleScreens()
    )

  iterateExampleScreens: ->

    #these should already be in this state the first time
    #but should be reset if back button was pressed from instruction screen
    $("#beginButton").hide()
    $("#nextButton").show()
    $("#backButton").show()
    @showNextTrial(@EXAMPLE_TRIALS[@currentExampleTrial])

    $("#nextButton").unbind().touchdown( =>
      @currentExampleTrial++
      if @currentExampleTrial <= @EXAMPLE_TRIALS.length - 1
        @iterateExampleScreens()
      else
        @showInstructionsScreen()
    )

    $("#backButton").unbind().touchdown( =>
      @currentExampleTrial--
      if @currentExampleTrial == 0
        @showStartScreen()
      else
        @iterateExampleScreens()
    )

  showInstructionsScreen: ->
    $("#exampleScreen").hide()
    $("#trialScreen").hide()
    $("#instructionsScreen").show()

    $("#nextButton").unbind().hide()
    $("#beginButton").unbind().show().touchdown( =>
      #start actual task
      @beginFirstExposureTrials()
    )

    $("#backButton").unbind().touchdown( =>
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
    trials = @generateExposureStimuli(@currentForm.FIRST_EXPOSURE)
    $("#nextButton").unbind().show().touchdown( =>
      $("#rememberScreen").hide()
      $("#nextButton").hide()
      @iterateFirstExposureTrials(trials)
    )

  beginSecondExposureTrials: ->
    @showRememberScreen()
    #generate trials for exposure
    trials = @generateExposureStimuli(@currentForm.SECOND_EXPOSURE)
    $("#nextButton").unbind().show().touchdown( =>
      $("#nextButton").hide()
      $("#rememberScreen").hide()
      @iterateSecondExposureTrials(trials)
    )

  beginFirstRecall: ->
    @showBlankScreen()

    trials = @generateRecalls(@currentForm.FIRST_RECALL)

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      @iterateFirstRecallTrials(trials)
    )

  beginSecondRecall: ->
    @showBlankScreen()

    trials = @generateRecalls(@currentForm.SECOND_RECALL)

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      @iterateSecondRecallTrials(trials)
    )

  iterateFirstRecallTrials: (trials) ->
    trial = trials.shift()
    @showNextTrial(trial)

    $(".nextButton").unbind().touchdown( =>
      if trials.length
        @iterateFirstRecallTrials(trials)
      else
        @beginSecondExposureTrials()
    )

  iterateSecondRecallTrials: (trials) ->

    @showNextTrial(trials.shift())

    $(".nextButton").unbind().touchdown( =>
      if trials.length
        @iterateSecondRecallTrials(trials)
      else
        @recallOneScoringScreen()
    )

  iterateFirstExposureTrials: (trials) ->
    @showNextTrial(trials.shift())

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      $(".encounterFace").fadeOut(@FADE_OUT_TIME)
      $("#rememberOne").fadeOut(@FADE_OUT_TIME)
    ).then( =>
      if trials.length
        @iterateFirstExposureTrials(trials)
      else
        @beginFirstRecall()
    )

  iterateSecondExposureTrials: (trials) ->
    @showNextTrial(trials.shift())

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      $(".encounterFace").fadeOut(@FADE_OUT_TIME)
      $("#rememberOne").fadeOut(@FADE_OUT_TIME)
    ).then( =>
      if trials.length
        @iterateSecondExposureTrials(trials)
      else
        @beginSecondRecall()
    )

  recallOneScoringScreen: ->
    $('#trialScreen').hide()
    $('#backButton').hide()
    $('#recallOneScoringScreen').show()
    $("#completeButton").unbind().hide()
    $("#recallOneScoringScreen")
      .find(".scoringFood span.currentSelection").unbind()
      .touchdown( (event) => @scoringTouchHandler(event, 'food') )

    $currentAnimal = $("#recallOneScoringScreen")
      .find(".scoringAnimal span.currentSelection")

    console.log $currentAnimal

    $("#recallOneScoringScreen")
      .find(".scoringAnimal span.currentSelection").unbind()
      .touchdown( (event) => @scoringTouchHandler(event, 'animal') )

    $("#nextButton").unbind().show().touchdown( =>
      $('#recallOneScoringScreen').hide()
      @recallTwoScoringScreen()
    )

  recallTwoScoringScreen: ->
    $('#nextButton').hide()
    $('#recallTwoScoringScreen').show()
    $('#backButton').unbind().show().touchdown( =>
      $('#recallTwoScoringScreen').hide()
      @recallOneScoringScreen()
    )

    $("#recallTwoScoringScreen")
      .find("span.scoringFood").unbind()
      .touchdown( (event) => @scoringTouchHandler(event, 'food') )

    $("#recallTwoScoringScreen")
      .find("span.scoringAnimal").unbind()
      .touchdown( (event) => @scoringTouchHandler(event, 'animal') )

    $("#completeButton").unbind().show().touchdown( =>
      console.log "closing task"
      #at this point, check to ensure we've answered all questions
      @endTask()
    )


@DelayMemoryTask = class extends MemoryTask
  constructor: ->
    super()

    @scoringSheets = [{
        label: "Delayed Recall"
        data: @buildScoringSheetsData(@currentForm)
    }]

    #generate pre-loaded images to switch out on the fly
    @preloadEncounterImageData($("#screenImage"), @currentForm.PEOPLE)
    @preloadScoringImageData(
      delayedRecallScoringScreen: @currentForm.DELAYED_RECALL
    )

    @state = @buildInitialState()

  buildInitialState: ->
    return {
      DELAYED_RECALL: @currentForm.DELAYED_RECALL
    }

  showStartScreen: ->
    @beginDelayedRecall()

  beginDelayedRecall: ->
    trials = @generateRecalls(@currentForm.DELAYED_RECALL)

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      @iterateDelayedRecallTrials(trials)
    )

  iterateDelayedRecallTrials: (trials) ->
    @showNextTrial(trials.shift())

    $(".nextButton").unbind().touchdown( =>
      if trials.length
        @iterateDelayedRecallTrials(trials)
      else
        @delayedScoringScreen()
    )

  delayedScoringScreen: ->
    $('#trialScreen').hide()
    $('#backButton').hide()
    $('#delayedRecallScoringScreen').show()

    console.log ($("#delayedRecallScoringScreen")
      .find("span.scoringFood"))

    $("#delayedRecallScoringScreen")
      .find("span.scoringFood").unbind()
      .touchdown( (event) => @scoringTouchHandler(event, 'food') )

    $("#delayedRecallScoringScreen")
      .find("span.scoringAnimal").unbind()
      .touchdown( (event) => @scoringTouchHandler(event, 'animal') )

    $("#completeButton").unbind().show().touchdown( =>
      console.log "closing task"
      #at this point, check to ensure we've answered all questions
      @endTask()
    )
