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

CHOICES = {
  ANIMAL: {
    DOLPHIN,
    WOLF,
    TURTLE,
    SHARK,
    COW
  },
  FOOD: {
    APPLE,
    POTATO,
    GRAPES,
    MELON,
    CARROTS
  }
}

SLIDES = [
  { type: 'firstExampleRemember', person: PEOPLE.MAN1, remember: 'food' },
  { type: 'exampleRemember', person: PEOPLE.WOMAN1 , remember: 'animal' },
  { type: 'exampleRecall', person: PEOPLE.MAN1, recall 'food' },
  { type: 'exampleRecall', person: PEOPLE.WOMAN1, recall 'animal' },
  #there should be a break here for the two slides, with click confirmation
  { type: 'rememberOne', person: PEOPLE.MAN2, remember: 'food' },
  { type: 'rememberOne', person: PEOPLE.WOMAN2, remember: 'animal' },
  { type: 'rememberOne', person: PEOPLE.WOMAN3, remember: 'food' },
  { type: 'rememberOne', person: PEOPLE.MAN2, remember: 'animal' },
  { type: 'rememberOne', person: PEOPLE.MAN3, remember: 'food' },
  { type: 'rememberOne', person: PEOPLE.WOMAN3, remember: 'animal' },
  { type: 'rememberOne', person: PEOPLE.MAN3, remember: 'animal' },
  { type: 'rememberOne', person: PEOPLE.WOMAN2, remember: 'food' },
  #blank slide
  { type: 'recallTwo', person: PEOPLE.MAN2 },
  { type: 'recallTwo', person: PEOPLE.WOMAN3 },
  { type: 'recallTwo', person: PEOPLE.WOMAN2 },
  { type: 'recallTwo', person: PEOPLE.MAN3 },
  #break here
  { type: 'rememberOne', person: PEOPLE.WOMAN2, remember: 'animal' },
  { type: 'rememberOne', person: PEOPLE.MAN2, remember: 'food' },
  { type: 'rememberOne', person: PEOPLE.WOMAN3, remember: 'animal' },
  { type: 'rememberOne', person: PEOPLE.MAN2, remember: 'animal' },
  { type: 'rememberOne', person: PEOPLE.WOMAN2, remember: 'food' },
  { type: 'rememberOne', person: PEOPLE.MAN3, remember: 'animal' },
  { type: 'rememberOne', person: PEOPLE.WOMAN3, remember: 'food' },
  { type: 'rememberOne', person: PEOPLE.MAN3, remember: 'food' },
  #blank
  { type: 'recallTwo', person: PEOPLE.MAN3 },
  { type: 'recallTwo', person: PEOPLE.MAN2 },
  { type: 'recallTwo', person: PEOPLE.WOMAN3 },
  { type: 'recallTwo', person: PEOPLE.WOMAN2 },

]

# main div's aspect ratio (pretend we're on an iPad)
ASPECT_RATIO = 4/3

showStartScreen = ->
  $startScreen = $('#startScreen')

  $startScreen.find('button').on('mousedown touchstart', ->
    $startScreen.hide()
    $('body').removeClass('blueBackground')
    showComets()
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

    TabCAT.UI.requireLandscapeMode($task)
    $task.on('mousedown touchstart', catchStrayTouchStart)

    TabCAT.UI.fixAspectRatio($rectangle, ASPECT_RATIO)
    TabCAT.UI.linkEmToPercentOfHeight($rectangle)

    showStartScreen()
  )
