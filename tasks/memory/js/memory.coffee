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
      instructions_before_face:
        1: 'You will need to remember people <br> and their favorite things.'
      instructions_favorite_food:
        1: 'For example, remember that her favorite food is an...'
      instructions_favorite_animal:
        1: 'And her favorite animal is a...'
      instructions_remember:
        1: 'Now you will see some more faces. ' +
           'You will see each face twice; once with their favorite ' +
           'food and once with their favorite animal.'
        2: 'Remember both.'
      instructions_ready:
        1: 'Are you ready to begin?'
      static_text:
        food: 'food'
        animal: 'animal'
        remember: 'Remember'
      button:
        back: 'Back'
        next: 'Next'
        begin: 'Begin'
        complete: 'Complete'
      animal:
        dolphin: 'dolphin'
        wolf: 'wolf'
        turtle: 'turtle'
        shark: 'shark'
        cow: 'cow'
        bear: 'bear'
        frog: 'frog'
        sheep: 'sheep'
        rabbit: 'rabbit'
        pig: 'pig'
        whale: 'whale'
        goat: 'goat'
        monkey: 'monkey'
        snake: 'snake'
        fox: 'fox'
        mouse: 'mouse'
        tiger: 'tiger'
      food:
        apple: 'apple'
        potato: 'potato'
        grapes: 'grapes'
        melon: 'melon'
        coconut: 'coconut'
        cherry: 'cherry'
        lettuce: 'lettuce'
        peas: 'peas'
        carrot: 'carrot'
        tomato: 'tomato'
        mushroom: 'mushroom'
        lemon: 'lemon'
        plum: 'plum'
        banana: 'banana'
        mango: 'mango'
        pepper: 'pepper'
        squash: 'squash'

  es:
    translation:
      instructions_before_face:
        1: 'Le vamos a mostrar fotos de personas junto a su alimento ' +
          'favorito y a su animal favorito.'
      instructions_favorite_food:
        1: 'Por ejemplo, recuerde que el alimento favorito de esta mujer es:'
      instructions_favorite_animal:
        1: 'Y el animal favorito de esta mujer es:'
      instructions_remember:
        1: 'Ahora vamos s a mostrarle mas personas. ' +
          'Le vamos a mostrar a cada persona dos veces, una vez con su ' +
          'alimento favorito y la otra con su animal favorito.'
        2: 'Recuerde ambas.'
      instructions_ready:
        1: '¿Esta listo para empezar?'
      static_text:
        food: 'alimento'
        animal: 'animal'
        remember: 'Recuerde'
      button:
        back: 'Retroceder'
        next: 'Siguiente'
        begin: 'Empiezar'
        complete: 'Ha finalizado'
      animal:
        dolphin: 'delfín'
        wolf: 'lobo'
        penguin: 'pinguino'
        turtle: 'tortuga'
        shark: 'tiburón'
        cow: 'vaca'
        bear: 'oso'
        frog: 'rana'
        toucan: 'tucán'
        lion: 'león'
        sheep: 'oveja'
        rabbit: 'conejo'
        giraffe: 'girafa'
        pig: 'cerdo'
        whale: 'ballena'
        octopus: 'pulpo'
        goat: 'cabra'
        monkey: 'mono'
        elephant: 'elefante'
        chipmunk: 'ardilla'
        camel: 'camello'
        snake: 'serpiente'
        fox: 'zorro'
        mouse: 'ratón'
        tiger: 'tigre'
      food:
        apple: 'manzana'
        garlic: 'ajo'
        celery: 'apio'
        potato: 'patata'
        mango: 'mango'
        cantaloupe: 'melón'
        eggplant: 'berenjena'
        onion: 'cebolla'
        pineapple: 'piña'
        grapes: 'uvas' #not sure if singular or plural is needed
        grape: 'uva'
        melon: 'melón'
        spinach: 'espinaca'
        lettuce: 'lechuga'
        coconut: 'coco'
        cherry: 'cereza'
        peas: 'chícharos'
        pear: 'pera'
        carrot: 'zanahoria'
        parsley: 'perejil'
        tomato: 'tomate'
        mushroom: 'seta'
        lemon: 'limón'
        orange: 'naranja'
        plum: 'ciruela'
        banana: 'plátano'
        pepper: 'pimienta'
        squash: 'squash'

MemoryTask = class
  constructor: ->

    @scores = {}

    # main div's aspect ratio (pretend we're on an iPad)
    @ASPECT_RATIO = 4/3

    # time values in milliseconds
    @TIME_BETWEEN_STIMULI = 3000

    @FADE_IN_TIME = 1000

    @FADE_OUT_TIME = 1000

    @currentRecallTrial = 0

  buildInitialState: (recalls) ->
    state = {}
    for recall in recalls
      do =>
        data = []
        _.each(@currentForm[recall], (person) ->
          data[person.person.KEY] = {
            person: person,
            food: null,
            animal: null
          }
        )
        state[recall] = data
    return state

  #returns a tuple
  getCurrentForm: ->
    form = window.localStorage.taskForm
    #remove this key so other tasks are not confused
    window.localStorage.removeItem('taskForm')

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
    people = currentForm.RECALL_ONE
    food = []
    animals = []
    for person in people
      do ( ->
        food.push(person.person.FOOD)
        animals.push(person.person.ANIMAL)
      )

    food = food.concat(["other", "DK"])
    animals = animals.concat(["other", "DK"])

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
      when "rememberOne" then \
        @rememberOne slide.person, slide.item
      when "recallBoth" then \
        @recallBoth slide.person

  showRememberScreen: ->
    $("#exampleScreen").hide()
    $("#trialScreen").hide()
    $("#instructionsScreen").hide()
    $("#rememberScreen").show()

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

    #moved here because data initialization requires i18n
    @initializeData()

    #this is the hook where task-specific setup may occur
    @setUpTask()

    $("body").i18n()

    $task = $('#task')
    $rectangle = $('#rectangle')

    TabCAT.UI.requireLandscapeMode($task)

    TabCAT.UI.fixAspectRatio($rectangle, @ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)

    @showStartScreen()

  initializeData: ->
    @CHOICES = {
      ANIMAL: {
        DOLPHIN: $.t('animal.dolphin'),
        WOLF: $.t('animal.wolf'),
        TURTLE: $.t('animal.turtle'),
        PENGUIN: $.t('animal.penguin'),
        SHARK: $.t('animal.shark'),
        BEAR: $.t('animal.bear'),
        COW: $.t('animal.cow'),
        LION: $.t('animal.lion'),
        GIRAFFE: $.t('animal.giraffe'),
        FROG: $.t('animal.frog'),
        SHEEP: $.t('animal.sheep'),
        RABBIT: $.t('animal.rabbit'),
        TOUCAN: $.t('animal.toucan'),
        PIG: $.t('animal.pig'),
        WHALE: $.t('animal.whale'),
        GOAT: $.t('animal.goat'),
        OCTOPUS: $.t('animal.octopus'),
        MONKEY: $.t('animal.monkey'),
        ELEPHANT: $.t('animal.elephant'),
        CHIPMUNK: $.t('animal.chipmunk'),
        SNAKE: $.t('animal.snake'),
        FOX: $.t('animal.fox'),
        MOUSE: $.t('animal.mouse'),
        TIGER: $.t('animal.tiger')
      },
      FOOD: {
        APPLE: $.t('food.apple'),
        CELERY: $.t('food.celery'),
        CANTALOUPE: $.t('food.cantaloupe'),
        EGGPLANT: $.t('food.eggplant'),
        POTATO: $.t('food.potato'),
        GRAPES: $.t('food.grapes'),
        GRAPE: $.t('food.grape'),
        MELON: $.t('food.melon'),
        GARLIC: $.t('food.garlic'),
        ONION: $.t('food.onion'),
        PINEAPPLE: $.t('food.pineapple'),
        COCONUT: $.t('food.coconut'),
        CHERRY: $.t('food.cherry'),
        LETTUCE: $.t('food.lettuce'),
        SPINACH: $.t('food.spinach'),
        PEAR: $.t('food.pear'),
        PEAS: $.t('food.peas'),
        CARROT: $.t('food.carrot'),
        TOMATO: $.t('food.tomato'),
        MUSHROOM: $.t('food.mushroom'),
        LEMON: $.t('food.lemon'),
        PLUM: $.t('food.plum'),
        BANANA: $.t('food.banana'),
        PARSLEY: $.t('food.parsely'),
        MANGO: $.t('food.mango'),
        ORANGE: $.t('food.orange'),
        PEPPER: $.t('food.pepper'),
        SQUASH: $.t('food.squash')
      }
    }

    @PEOPLE = {
      MAN_EXAMPLE:
        KEY: 'man-example'
        IMAGE: 'man-example.jpg'
      MAN_1:
        KEY: 'man1'
        IMAGE: 'man1.jpg'
        ITEMS:
          ENGLISH:
            FOOD: @CHOICES.FOOD.MELON
            ANIMAL: @CHOICES.ANIMAL.RABBIT
          LATIN:
            FOOD: @CHOICES.FOOD.ONION
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
      MAN_9:
        KEY: 'man9'
        IMAGE: 'man9.jpg'
        FOOD: @CHOICES.FOOD.PLUM
        ANIMAL: @CHOICES.ANIMAL.PIG
      MAN_10:
        KEY: 'man10'
        IMAGE: 'man10.jpg'
        FOOD: @CHOICES.FOOD.MELON
        ANIMAL: @CHOICES.ANIMAL.RABBIT
      MAN_11:
        KEY: 'man11'
        IMAGE: 'man11.jpg'
        FOOD: @CHOICES.FOOD.POTATO
        ANIMAL: @CHOICES.ANIMAL.FROG
      WOMAN_EXAMPLE:
        KEY: 'woman-example'
        IMAGE: 'woman-example.jpg'
        FOOD: @CHOICES.FOOD.APPLE
        ANIMAL: @CHOICES.ANIMAL.DOLPHIN
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
      WOMAN_9:
        KEY: 'woman9'
        IMAGE: 'woman9.jpeg'
        FOOD: @CHOICES.FOOD.GRAPES
        ANIMAL: @CHOICES.ANIMAL.SHEEP
    }

    @EXAMPLE_PEOPLE = [
      @PEOPLE.WOMAN_EXAMPLE
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
        RECALL_ONE: [
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
        RECALL_TWO: [
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
          @PEOPLE.MAN_10,
          @PEOPLE.MAN_11,
          @PEOPLE.WOMAN_9,
          @PEOPLE.WOMAN_2
        ]
        FIRST_EXPOSURE: [
          { person: @PEOPLE.WOMAN_9, item: 'animal'},
          { person: @PEOPLE.WOMAN_2, item: 'food' },
          { person: @PEOPLE.MAN_11, item: 'animal' },
          { person: @PEOPLE.WOMAN_9, item: 'food'},
          { person: @PEOPLE.MAN_10, item: 'animal' },
          { person: @PEOPLE.MAN_11, item: 'food' },
          { person: @PEOPLE.WOMAN_2, item: 'animal' },
          { person: @PEOPLE.MAN_10, item: 'food' }
        ],
        RECALL_ONE: [
          { person: @PEOPLE.WOMAN_9 },
          { person: @PEOPLE.MAN_11 },
          { person: @PEOPLE.WOMAN_2 },
          { person: @PEOPLE.MAN_10 }
        ],
        SECOND_EXPOSURE: [
          { person: @PEOPLE.MAN_11, item: 'animal' },
          { person: @PEOPLE.WOMAN_9, item: 'food' },
          { person: @PEOPLE.MAN_10, item: 'food' },
          { person: @PEOPLE.WOMAN_2, item: 'food' },
          { person: @PEOPLE.WOMAN_9, item: 'animal' },
          { person: @PEOPLE.MAN_10, item: 'animal' },
          { person: @PEOPLE.MAN_11, item: 'food' },
          { person: @PEOPLE.WOMAN_2, item: 'animal' }
        ],
        RECALL_TWO: [
          { person: @PEOPLE.MAN_11 },
          { person: @PEOPLE.WOMAN_9 },
          { person: @PEOPLE.WOMAN_2 },
          { person: @PEOPLE.MAN_10 }
        ],
        DELAYED_RECALL: [
          { person: @PEOPLE.WOMAN_2 },
          { person: @PEOPLE.MAN_10 },
          { person: @PEOPLE.WOMAN_9 },
          { person: @PEOPLE.MAN_11 }
        ]
      FORM_THREE:
        PEOPLE: [
          @PEOPLE.MAN_9,
          @PEOPLE.MAN_4,
          @PEOPLE.WOMAN_3,
          @PEOPLE.WOMAN_4
        ]
        FIRST_EXPOSURE: [
          { person: @PEOPLE.MAN_9, item: 'food' },
          { person: @PEOPLE.WOMAN_4, item: 'food' },
          { person: @PEOPLE.MAN_4, item: 'animal' },
          { person: @PEOPLE.WOMAN_4, item: 'animal' },
          { person: @PEOPLE.WOMAN_3, item: 'food' },
          { person: @PEOPLE.MAN_4, item: 'food'},
          { person: @PEOPLE.MAN_9, item: 'animal' },
          { person: @PEOPLE.WOMAN_3, item: 'animal' }
        ],
        RECALL_ONE: [
          { person: @PEOPLE.WOMAN_3 },
          { person: @PEOPLE.MAN_9 },
          { person: @PEOPLE.MAN_4 },
          { person: @PEOPLE.WOMAN_4 }
        ],
        SECOND_EXPOSURE: [
          { person: @PEOPLE.MAN_4, item: 'animal' },
          { person: @PEOPLE.MAN_9, item: 'food' },
          { person: @PEOPLE.WOMAN_3, item: 'animal' },
          { person: @PEOPLE.MAN_4, item: 'food' },
          { person: @PEOPLE.WOMAN_4, item: 'food' }
          { person: @PEOPLE.MAN_9, item: 'animal'}
          { person: @PEOPLE.WOMAN_3, item: 'food' },
          { person: @PEOPLE.WOMAN_4, item: 'animal' }
        ],
        RECALL_TWO: [
          { person: @PEOPLE.MAN_9 },
          { person: @PEOPLE.WOMAN_3 },
          { person: @PEOPLE.MAN_4 },
          { person: @PEOPLE.WOMAN_4 }
        ],
        DELAYED_RECALL: [
          { person: @PEOPLE.WOMAN_4 },
          { person: @PEOPLE.MAN_4 },
          { person: @PEOPLE.WOMAN_3 },
          { person: @PEOPLE.MAN_9 }
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
        RECALL_ONE: [
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
        RECALL_TWO: [
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
            $container.data('person', person.person.KEY)
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

    $food = $('<ul></ul>').addClass('foodSelection selectionColumn')
    for food in data.food
      do =>
        $li = $('<li></li>')
        if food == correctFood
          $li.addClass('correctFood')
        $li.html(food)
        $li.data('food', food)
        $food.append($li)

    return $food

  buildAnimalOptions: (correctAnimal) ->
    data = @buildScoringSheetsData(@currentForm)

    $animal = $('<ul></ul>').addClass('animalSelection selectionColumn')
    for animal in data.animals
      do =>
        $li = $('<li></li>')
        if animal == correctAnimal
          $li.addClass('correctAnimal')
        $li.html(animal)
        $li.data('animal', animal)
        $animal.append($li)

    return $animal

  showPerson: (person, fadeIn = false) ->
    $(".encounterFace").hide()
    $image = $(".encounterFace[data-person='" + person.KEY + "']")
    if fadeIn
      $image.fadeIn(@FADE_IN_TIME)
    else
      $image.show()

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

    @showPerson(person)
    $("#recallBoth").show()
    $("#recallNextButton").show()
    $("#trialScreen").show()

  scoringTouchHandler: (event, type, scoringScreen) ->
    #default to animalSelection
    className = '.foodSelection'
    parentClass = '.scoringFood'
    if type == 'animal'
      className = '.animalSelection'
      parentClass = '.scoringAnimal'

    $target = $(event.target)
    $scoringElement = $target.parent('.selectionColumn').parent(parentClass)
    $scoringElement.find('.currentSelection').removeClass('currentSelection')
    $scoringColumn = $scoringElement.parent('.scoringColumn')
    #previously set key on row container
    personKey = $scoringColumn.data('person')

    touched = $(event.target).data(type)
    #set the current display to what we just touched
    $target.html(touched).addClass('currentSelection')

    #set the state's touched answer where the scoringScreen is current
    #and the person's key matches personKey
    @state[scoringScreen][personKey][type] = touched

  endTask: ->

    #there is currently no real event data since
    #this is more of an examiner task
    TabCAT.Task.logEvent(@state)

    TabCAT.Task.finish()

@LearningMemoryTask = class extends MemoryTask
  constructor: ->
    super()

    @currentExampleTrial = 0

  setUpTask: ->
    @state = @buildInitialState(["RECALL_ONE", "RECALL_TWO"])

    #generate pre-loaded images to switch out on the fly
    #concat'ing examples for first trials to work with same html
    encounterPeople = @EXAMPLE_PEOPLE.concat(@currentForm.PEOPLE)

    @preloadEncounterImageData($("#screenImage"), encounterPeople)
    @preloadScoringImageData(
      recallOneScoringScreen: @currentForm.RECALL_ONE
      recallTwoScoringScreen: @currentForm.RECALL_TWO
    )

  showStartScreen: ->
    $("#backButton").hide()
    $("#trialScreen").hide()

    $("#rememberOne").hide()

    $("#supplementaryInstruction").hide()

    $("#instructionsScreen").show()
    html = @getTranslatedParagraphs('instructions_before_face')

    $("#instructionsScreen div#instructions").html(html)

    $("#nextButton").unbind().show().touchdown( =>
      @instructionsFavoriteFood()
    )

  instructionsFavoriteFood: ->
    $("#instructionsScreen").hide()
    $("#recallBoth").hide()

    html = @getTranslatedParagraphs('instructions_favorite_food')

    $("#supplementaryInstruction").show().html(html)

    person = @EXAMPLE_PEOPLE[0]

    @showPerson(person)
    $("#rememberOne").show().empty().html(
      '<p>' + person.FOOD + '</p>' )
    $("#trialScreen").show()

    $("#backButton").unbind().show().touchdown( =>
      @showStartScreen()
    )

    $("#nextButton").unbind().show().touchdown( =>
      @instructionsFavoriteAnimal()
    )

  instructionsFavoriteAnimal: ->

    $("#instructionsScreen").hide()
    $("#recallBoth").hide()

    html = @getTranslatedParagraphs('instructions_favorite_animal')

    $("#supplementaryInstruction").show().html(html)

    person = @EXAMPLE_PEOPLE[0]

    @showPerson(person)
    $("#rememberOne").show().empty().html(
      '<p>' + person.ANIMAL + '</p>' )
    $("#trialScreen").show()

    $("#backButton").unbind().show().touchdown( =>
      @instructionsFavoriteFood()
    )

    $("#nextButton").unbind().show().touchdown( =>
      @instructionsRecallBoth()
    )

  instructionsRecallBoth: ->

    $("#trialScreen").show()
    $("#instructionsScreen").hide()

    $("#rememberOne").hide()
    $("#recallBoth").show()
    $("#recallNextButton").hide()
    $("#recallPreviousButton").hide()

    $("#supplementaryInstruction").hide()

    $("#backButton").unbind().show().touchdown( =>
      @instructionsFavoriteAnimal()
    )

    $("#nextButton").unbind().show().touchdown( =>
      @instructionsRemember()
    )

  instructionsRemember: ->

    $("#instructionsScreen").show()

    html = @getTranslatedParagraphs('instructions_remember')

    $("#instructionsScreen div#instructions").html(html)

    $("#backButton").unbind().show().touchdown( =>
      @instructionsRecallBoth()
    )

    $("#nextButton").unbind().show().touchdown( =>
      @instructionsReady()
    )

  instructionsReady: ->
    $("#nextButton").hide()
    $("#instructionsScreen").show()

    html = @getTranslatedParagraphs('instructions_ready')

    $("#instructionsScreen div#instructions").html(html)

    $("#backButton").unbind().show().touchdown( =>
      @instructionsRemember()
    )

    $("#beginButton").unbind().show().touchdown( =>
      @beginFirstExposureTrials()
    )

  getTranslatedParagraphs: (toTranslate) ->
    translatedText = $.t(toTranslate, {returnObjectTrees: true})
    html = _.map(translatedText, (value, key) ->
      '<p>' + value + '</p>')
    return html

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

    trials = @generateRecalls(@currentForm.RECALL_ONE)

    @currentRecallTrial = 0

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      @iterateFirstRecallTrials(trials)
    )

  beginSecondRecall: ->
    @showBlankScreen()

    trials = @generateRecalls(@currentForm.RECALL_TWO)

    @currentRecallTrial = 0

    TabCAT.UI.wait(@TIME_BETWEEN_STIMULI).then( =>
      @iterateSecondRecallTrials(trials)
    )

  iterateFirstRecallTrials: (trials) ->
    if @currentRecallTrial == 0
      $("#recallPreviousButton").unbind().hide()

    currentTrial = trials[@currentRecallTrial]

    @showNextTrial(currentTrial)

    $("#recallNextButton").unbind().touchdown( =>
      if trials[@currentRecallTrial + 1]
        @currentRecallTrial++

        $("#recallPreviousButton").unbind().show().touchdown( =>
          if trials[@currentRecallTrial - 1]
            @currentRecallTrial--
            @iterateFirstRecallTrials(trials)
        )

        @iterateFirstRecallTrials(trials)
      else
        $("#recallPreviousButton").unbind().hide()
        $("#recallNextButton").unbind().hide()
        @beginSecondExposureTrials()
    )

  iterateSecondRecallTrials: (trials) ->
    if @currentRecallTrial == 0
      $("#recallPreviousButton").unbind().hide()

    currentTrial = trials[@currentRecallTrial]

    @showNextTrial(currentTrial)

    $("#recallNextButton").unbind().touchdown( =>
      if trials[@currentRecallTrial + 1]
        @currentRecallTrial++

        $("#recallPreviousButton").unbind().show().touchdown( =>
          if trials[@currentRecallTrial - 1]
            @currentRecallTrial--
            @iterateSecondRecallTrials(trials)
        )

        @iterateSecondRecallTrials(trials)
      else
        $("#recallPreviousButton").unbind().hide()
        $("#recallNextButton").unbind().hide()
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
      .find(".scoringFood ul")
      .unbind().touchdown( (event) =>
        @scoringTouchHandler(event, 'food', 'RECALL_ONE')
      )

    $("#recallOneScoringScreen")
      .find(".scoringAnimal ul")
      .unbind().touchdown( (event) =>
        @scoringTouchHandler(event, 'animal', 'RECALL_ONE')
      )

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
      .find(".scoringFood ul")
      .unbind().touchdown( (event) =>
        @scoringTouchHandler(event, 'food', 'RECALL_TWO')
      )

    $("#recallTwoScoringScreen")
      .find(".scoringAnimal ul")
      .unbind().touchdown( (event) =>
        @scoringTouchHandler(event, 'animal', 'RECALL_TWO')
      )

    $("#completeButton").unbind().show().touchdown( =>
      #at this point, check to ensure we've answered all questions
      @endTask()
    )


@DelayMemoryTask = class extends MemoryTask
  constructor: ->
    super()

  setUpTask: ->
    #generate pre-loaded images to switch out on the fly
    @preloadEncounterImageData($("#screenImage"), @currentForm.PEOPLE)
    @preloadScoringImageData(
      delayedRecallScoringScreen: @currentForm.DELAYED_RECALL
    )

    @state = @buildInitialState(["DELAYED_RECALL"])

  showStartScreen: ->
    $("completeButton").hide()
    @beginDelayedRecall()

  beginDelayedRecall: ->
    trials = @generateRecalls(@currentForm.DELAYED_RECALL)
    @currentRecallTrial = 0
    @iterateDelayedRecallTrials(trials)

  iterateDelayedRecallTrials: (trials) ->

    if @currentRecallTrial == 0
      $("#recallPreviousButton").unbind().hide()

    currentTrial = trials[@currentRecallTrial]

    @showNextTrial(currentTrial)

    $("#recallNextButton").unbind().touchdown( =>
      if trials[@currentRecallTrial + 1]
        @currentRecallTrial++

        $("#recallPreviousButton").unbind().show().touchdown( =>
          if trials[@currentRecallTrial - 1]
            @currentRecallTrial--
            @iterateDelayedRecallTrials(trials)
        )

        @iterateDelayedRecallTrials(trials)
      else
        $("#recallNextButton").unbind().hide()
        $("#recallPreviousButton").unbind().hide()
        @delayedScoringScreen()
    )

  delayedScoringScreen: ->
    $('#trialScreen').hide()
    $('#backButton').hide()
    $('#delayedRecallScoringScreen').show()

    $("#delayedRecallScoringScreen")
      .find(".scoringFood ul")
      .unbind().touchdown( (event) =>
        @scoringTouchHandler(event, 'food', 'DELAYED_RECALL')
      )

    $("#delayedRecallScoringScreen")
      .find(".scoringAnimal ul")
      .unbind().touchdown( (event) =>
        @scoringTouchHandler(event, 'animal', 'DELAYED_RECALL')
      )

    $("#completeButton").unbind().show().touchdown( =>
      #at this point, check to ensure we've answered all questions
      @endTask()
    )




    
