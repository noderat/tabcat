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

# main div's aspect ratio (pretend we're on an iPad)
ASPECT_RATIO = 4/3

# the minimum number of target stars to show
MIN_TARGET_STARS = 1

# the maximum number of target stars to show
MAX_TARGET_STARS = 6

# the maximum number of times we can randomly fail to place a star
# before restarting the process
MAX_FAILURES = 30

# stars' centers can never be less than this many star diameters apart
MIN_STAR_DISTANCE = 2

# target stars' centers can never be more than this many star diameters apart
MAX_TARGET_STAR_DISTANCE = 6

# Distances distractor stars should be from target stars. They should
# also be at least this far from any other target stars and any stars
# currently displayed
DISTRACTOR_STAR_DISTANCES = [4, 3]

# how many star diameters high the sky div is
SKY_HEIGHT = 12

# how many star diameters wide the sky div is
SKY_WIDTH = SKY_HEIGHT * ASPECT_RATIO

# stars' centers should be at least this many star diameters from the
# edges of the sky div. This isn't actual CSS, but it works the same way
#
# leaving a larger margin at the top leaves space for the
# "which star did you just see?" message, and keeps us away from the
# status bar
SKY_TOP = 4.5
SKY_BOTTOM = SKY_HEIGHT - 2.5
SKY_LEFT = 2.5
SKY_RIGHT = SKY_WIDTH - 2.5

# path for the star image
STAR_IMG_PATH = 'img/star.png'

# how many star diameters the star image file is
# (the star fades smoothly, so this is kind of a judgment call).
# the star's <img> element also serves as its target area for touch events
#
# Make sure this isn't bigger than MIN_STAR_DISTANCE / sqrt(2), so that
# target areas can't touch.
STAR_IMG_WIDTH = STAR_IMG_HEIGHT = 1.4

# minimum y-coordinate for top of screen, in star coordinates
# (it can't be any less than this because we don't allow portrait mode)
SCREEN_MIN_Y = Math.min(0, (SKY_HEIGHT - SKY_WIDTH) / 2)

# max y-coordinate for bottom of screen, in star coordinates
SCREEN_MAX_Y = Math.max(SKY_HEIGHT, SCREEN_MIN_Y + SKY_WIDTH)

# how many meteors should we show?
NUM_METEORS = 5

# path for the meteor image
METEOR_IMG_PATH = 'img/meteor.png'

# how many star diameters the meteor image file is
METEOR_IMG_WIDTH = METEOR_IMG_HEIGHT = 9

# the tracks meteors follow must be at least this many star diameters apart
MIN_METEOR_TRACK_SPACING = 2

# meteors' centers must be at least this far apart
MIN_METEOR_DISTANCE = 5

# where in the meteor sky can meteors be centered?
METEOR_MIN_X = 0
METEOR_MIN_Y = 0
METEOR_MAX_X = SKY_WIDTH
METEOR_MAX_Y = SKY_HEIGHT

# Where does the meteor sky start its animation (upper-left corner)?
#
# This positions the sky just off-screen when the screen is nearly square
#
# Meteors always travel at a 45-degree angle, down and to the right,
# so x and y coordinates are the same.
METEOR_START_XY = SCREEN_MIN_Y - METEOR_MAX_Y - (METEOR_IMG_HEIGHT / 2)

# where does the meteor sky end its animation? (upper-left corner)
#
# This gives the meteors a little extra distance after they leave even
# the squares of screens, which seems to help on slow devices
METEOR_END_XY = SCREEN_MAX_Y - METEOR_MIN_Y + (3 * METEOR_IMG_HEIGHT / 2)

# how long does the meteor sky's animation last
METEOR_DURATION = 1200

# how long a fade in should take, in msec
FADE_DURATION = 400

# how long the "remember these star(s)" message shows (not including fades)
REMEMBER_MSG_DURATION = 1500

# how long to display target stars (not including fades)
TARGET_STAR_DURATION = 2000


# return x squared
sq = (x) ->
  x * x


# return the distance between two points, squared
distSq = ([x1, y1], [x2, y2]) ->
  sq(x2 - x1) + sq(y2 - y1)


# convert star x-coordinate/width to a % of sky width (for use in CSS)
starXToSky = (x) ->
  (100 * x / SKY_WIDTH) + '%'

# convert star y-coordinate/height to a % of sky height (for use in CSS)
starYToSky = (y) ->
  (100 * y / SKY_HEIGHT) + '%'


# helper for makeStarImg and makeMeteorImg
makeImg = ([x, y], [width, height], attrs) ->
  $img = $('<img>')

  for own key, value of attrs
    $img.attr(key, value)

  $img.css(
    left: starXToSky(x - width / 2)
    top: starYToSky(y - height / 2)
  )

  $img.attr('width', starXToSky(width))
  $img.attr('height', starYToSky(height))

  return $img


# convert star center (in star coordinates) to an image tag
makeStarImg = ([x, y]) ->
  makeImg([x, y], [STAR_IMG_WIDTH, STAR_IMG_HEIGHT],
    class: 'star', src: STAR_IMG_PATH)


# convert meteor center (in star coordinates) to an image tag
makeMeteorImg = ([x, y]) ->
  makeImg([x, y], [METEOR_IMG_WIDTH, METEOR_IMG_HEIGHT],
    class: 'star', src: METEOR_IMG_PATH)


# helper for makeStarImg and makeMeteorImgAndAnimation
makeImg = ([x, y], [width, height], attrs) ->
  $img = $('<img>')

  for own key, value of attrs
    $img.attr(key, value)

  $img.css(
    left: starXToSky(x - width / 2)
    top: starYToSky(y - height / 2)
  )

  $img.attr('width', starXToSky(width))
  $img.attr('height', starYToSky(height))

  return $img


# used by untilSucceeds (below)
class Failure


# there's lots of space for stars, but it's possible to get into a state where
# we've randomly selected some of the stars and it's impossible to proceed, and
# we have to start the random selection process from the beginning.
#
# untilSucceeds() calls a function a certain number of times, and then raises
# Failure. It also gracefully handles Failure, allowing you to nest it.
#
# if maxFailures is null, tries forever
untilSucceeds = (f, maxFailures) ->
  numFailures = 0

  while true
    try
      return f()
    catch error
      if error not instanceof Failure
        throw error

    numFailures += 1
    if maxFailures? and numFailures > maxFailures
      throw new Failure


# pick coordinates for a star at random
pickStarInSky = ->
  # we're positioning centers of the stars and the padding specifies
  # edges, so make the range smaller by the stars' radius (0.5)
  [
    tabcat.math.randomUniform(SKY_LEFT, SKY_RIGHT)
    tabcat.math.randomUniform(SKY_TOP, SKY_BOTTOM)
  ]


# pick center coordinates of a meteor
pickMeteor = ->
  [
    tabcat.math.randomUniform(METEOR_MIN_X, METEOR_MAX_X),
    tabcat.math.randomUniform(METEOR_MIN_Y, METEOR_MAX_Y),
  ]


# pick a field of n meteors
pickMeteors = (n) ->
  untilSucceeds(->
    meteors = []

    while meteors.length < n
      meteors.push(
        untilSucceeds((-> nextMeteor(meteors)), MAX_FAILURES))

    return meteors
  )


# randomly pick next meteor for a group, throwing Failure if it's
# too close to existing meteors
nextMeteor = (meteors) ->
  # come up with a number indicating which track this meteor will follow
  track = ([x, y]) ->
    x - y

  candidateMeteor = pickMeteor()
  candidateTrack = track(candidateMeteor)

  for meteor in meteors
    # tracks are at a 45-degree angle, so for tracks to be 1 unit apart,
    # x - y has to be at least sqrt(2) apart
    if sq(track(meteor) - candidateTrack) < sq(MIN_METEOR_TRACK_SPACING) * 2
      throw new Failure

    if distSq(meteor, candidateMeteor) < sq(MIN_METEOR_DISTANCE)
      throw new Failure

  return candidateMeteor


# is the given star in the sky?
isInSky = ([x, y]) ->
  SKY_LEFT <= x <= SKY_RIGHT and SKY_TOP <= y <= SKY_BOTTOM


# pick *n* target stars at random, and then pick 3 test stars
#
# we do these together because there are some target star configurations
# for which there are no valid test stars
pickTargetAndTestStars = (n) ->
  untilSucceeds(->
    targetStars = []

    while targetStars.length < n
      targetStars.push(
        untilSucceeds((-> nextTargetStar(targetStars)), MAX_FAILURES))

    # start with the correct choice
    testStars = [_.sample(targetStars)]

    for distance in DISTRACTOR_STAR_DISTANCES
      testStars.push(untilSucceeds(
        (-> nextDistractorStar(distance, testStars, targetStars)),
        MAX_FAILURES))

    return [targetStars, testStars]
  )


# return a target star that works with the existing stars, or undefined
nextTargetStar = (stars) ->
  candidateStar = pickStarInSky()
  if canAddTargetStar(candidateStar, stars)
    candidateStar
  else
    throw new Failure


# is candidateStar not too close or too far from the other target stars?
canAddTargetStar = (candidateStar, stars) ->
  if stars.length is 0
    true
  else if isCloserThanToAny(candidateStar, MIN_STAR_DISTANCE, stars)
    false
  else
    isCloserThanToAny(candidateStar, MAX_TARGET_STAR_DISTANCE, stars)


# return true if *candidateStar* is closer than *distance* to any of *stars*
isCloserThanToAny = (candidateStar, distance, stars) ->
  for star in stars
    if distSq(candidateStar, star) < sq(distance)
      return true
  return false


# pick one of the target stars and add distractors.
#
# returns a list of points; the first one is the correct answer
pickTestStars = (targetStars) ->
  untilSucceeds(->
    # start with the correct choice
    stars = [_.sample(targetStars)]

    for distance in DISTRACTOR_STAR_DISTANCES
      stars.push(untilSucceeds(
        (-> nextDistractorStar(distance, stars, targetStars)),
        MAX_FAILURES))

    return stars
  )


# pick a distractor star at the given distance, at random, or throw Failure
nextDistractorStar = (distance, stars, targetStars) ->
  targetStar = _.sample(targetStars)
  otherStars = _.without(stars.concat(targetStars), targetStar)

  candidateStar = pickStarAtDistanceFrom(distance, targetStar)

  if (isInSky(candidateStar) and \
      not isCloserThanToAny( \
        candidateStar, Math.max(distance, MIN_STAR_DISTANCE), otherStars))
    return candidateStar
  else
    throw new Failure



# randomly pick a star that is the given distance from another star
#
# may return stars outside the sky! use isInSky()
pickStarAtDistanceFrom = (distance, [x, y]) ->
  angle = tabcat.math.randomUniform(0, 2 * Math.PI)
  return [x + Math.cos(angle) * distance, y + Math.sin(angle) * distance]




# show stars to remember.
#
# This is also responsible for setting everything up (stars in sky,
# meteors, messages)
showTargetStars = ->
  $rememberMsg = $('#rememberMsg')
  $targetSky = $('#targetSky')
  $testSky = $('#testSky')
  $meteorSky = $('#meteorSky')

  $targetSky.hide()
  $meteorSky.hide()
  $rememberMsg.hide()


  numTargetStars = _.random(1, MAX_TARGET_STARS)

  if numTargetStars > 1
    $rememberMsg.text('Remember these stars')
  else
    $rememberMsg.text('Remember this star')

  $testSky.hide()

  $rememberMsg.fadeIn(duration: FADE_DURATION)

  # start the clock for when we want to hide the message
  showedMsgLongEnough = tabcat.ui.wait(FADE_DURATION + REMEMBER_MSG_DURATION)

  # pick stars/meteors and set them up while message is being shown
  [targetStars, testStars] = pickTargetAndTestStars(numTargetStars)

  setUpTargetSky(targetStars)
  setUpTestSky(testStars)

  meteors = pickMeteors(NUM_METEORS)
  setUpMeteorSky(meteors)

  showedMsgLongEnough.then(->
    $rememberMsg.fadeOut(
      duration: FADE_DURATION
      complete: ->
        $targetSky.fadeIn(duration: FADE_DURATION)
        tabcat.ui.wait(TARGET_STAR_DURATION).then(showTestStars)
    )
  )


# set up the #targetSky div. Not responsible for hiding/showing it
setUpTargetSky = (targetStars) ->
  $targetSky = $('#targetSky')

  $targetSky.empty()
  for targetStar in targetStars
    $targetSky.append(makeStarImg(targetStar))


# set up the #testSky div, including the "which star did you just see?"
# message. Not responsible for hiding/showing it
setUpTestSky = (testStars) ->
  $testSky = $('#testSky')

  $testSky.empty()

  for testStar, i in testStars
    $testStarImg = makeStarImg(testStar)
    $testStarImg.one('mousedown touchStart', i, (event) ->
      event.preventDefault()
      i = event.data
      if i is 0
        console.log('correct!')
      else
        console.log(
          'distractor at distance ' + DISTRACTOR_STAR_DISTANCES[i - 1])

      showTargetStars()
    )
    $testSky.append($testStarImg)

    $whichStarMsg = $('<div></div>', id: 'whichStarMsg', class: 'msg')
    $whichStarMsg.text('Which star did you just see?')
    $testSky.append($whichStarMsg)


# setup the #meteorSky div. Not responsible for hiding/showing it,
# but does put it in the correct initial position
setUpMeteorSky = (meteors) ->
  $meteorSky = $('#meteorSky')

  $meteorSky.empty()

  for meteor in meteors
    $meteorSky.append(makeMeteorImg(meteor))

  $meteorSky.css(
    left: starXToSky(METEOR_START_XY)
    top: starYToSky(METEOR_START_XY)
  )


# show star(s) to match against the target stars, after clearing
# the screen with randomly chosen meteors
showTestStars = ->
  $targetSky = $('#targetSky')
  $testSky = $('#testSky')
  $meteorSky = $('#meteorSky')

  $targetSky.hide()
  $meteorSky.show()

  $meteorSky.animate({
    left: starXToSky(METEOR_END_XY),
    top: starYToSky(METEOR_END_XY)
  }, {
    duration: METEOR_DURATION
    easing: 'linear'
    complete: ->
      $meteorSky.hide()
      $testSky.fadeIn(duration: FADE_DURATION)
  })


# INITIALIZATION
@initTask = ->
  tabcat.task.start(trackViewport: true)

  tabcat.ui.turnOffBounce()

  $(->
    tabcat.ui.requireLandscapeMode($('#task'))
    tabcat.ui.fixAspectRatio($('#rectangle'), ASPECT_RATIO)
    tabcat.ui.linkEmToPercentOfHeight($('#rectangle'))

    # don't let this get in the way of touch events
    $('#meteorSky').hide()

    showTargetStars()
  )
