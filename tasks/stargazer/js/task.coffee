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

# star centers should be at least this many star diameters from the
# edge of the sky div
SKY_BORDER = MIN_STAR_DISTANCE

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

# path for the meteor image
METEOR_IMG_PATH = 'img/meteor.png'

# how many star diameters the meteor image file is
METEOR_IMG_WIDTH = METEOR_IMG_HEIGHT = 5

# how much the Y coordinate of meteors can vary randomly
METEOR_Y_RANGE = METEOR_IMG_HEIGHT * 2

# max Y coordinate for meteor
METEOR_MAX_Y = SCREEN_MIN_Y - (METEOR_IMG_HEIGHT / 2)

# min Y coordinate for meteor
METEOR_MIN_Y = METEOR_MAX_Y - METEOR_Y_RANGE

# min X coordinate for meteor (so it can pass through the lower-left corner
# of the sky no matter how low it starts)
METEOR_MIN_X = METEOR_MAX_Y - SKY_HEIGHT

# max X coordinate for meteor (so it can pass through the upper-right corner
# of the sky no matter how high it starts)
METEOR_MAX_X = SKY_WIDTH + METEOR_MIN_Y

# how much to change a meteor's x/y coordinates to make it travel
# through a path?
# (meteors always travel at a 45-degree angle, down and to the right)
METEOR_PATH_XY = (
  SCREEN_MAX_Y - SCREEN_MIN_Y + METEOR_IMG_HEIGHT + METEOR_Y_RANGE)

# how many meteors should we show?
NUM_METEORS = 15

# how long should meteor animation take? (in msec)
METEOR_DURATION = 1000

# how long a fade should take, in msec
FADE_DURATION = 400


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


# helper for makeStarImg and makeMeteorImgAndAnimation
makeImg = ([x1, y1], [width, height], attrs) ->
  $img = $('<img>')

  for own key, value of attrs
    $img.attr(key, value)

  $img.css(
    left: starXToSky(x1 - width / 2)
    top: starYToSky(y1 - height / 2)
  )

  $img.attr('width', starXToSky(width))
  $img.attr('height', starYToSky(height))

  return $img


# convert star center (in star-diameter coordinates) to an image tag to add
# to the sky div
makeStarImg = ([x1, y1]) ->
  makeImg([x1, y1], [STAR_IMG_WIDTH, STAR_IMG_HEIGHT],
    class: 'star', src: STAR_IMG_PATH)


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
  [
    tabcat.math.randomUniform(SKY_BORDER, SKY_WIDTH - SKY_BORDER),
    tabcat.math.randomUniform(SKY_BORDER, SKY_HEIGHT - SKY_BORDER)
  ]


# is the given star in the sky?
isInSky = ([x, y]) ->
  SKY_BORDER <= x <= SKY_WIDTH - SKY_BORDER and \
  SKY_BORDER <= y <= SKY_HEIGHT - SKY_BORDER


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





showTargetStars = ->
  if event?.preventDefault?
    event.preventDefault()

  $sky = $('<div></div>', class: 'sky')
  [targetStars, testStars] = pickTargetAndTestStars(MAX_TARGET_STARS)
  for targetStar in targetStars
    $sky.append(makeStarImg(targetStar))

  $sky.hide()
  $('#rectangle').empty()
  $('#rectangle').append($sky)

  $sky.on('mousedown touchStart', (event) ->
    event.preventDefault()
    showTestStars(testStars)
  )

  $sky.fadeIn(fadeDuration: FADE_DURATION)


showTestStars = (testStars) ->
  if event?.preventDefault?
    event.preventDefault()

  $sky = $('<div></div>', class: 'sky')
  for testStar, i in testStars
    $testStarImg = makeStarImg(testStar)
    $testStarImg.on('mousedown touchStart', i, (event) ->
      event.preventDefault()
      i = event.data
      if i is 0
        showTargetStars()
      else
        alert('distractor at distance ' + DISTRACTOR_STAR_DISTANCES[i - 1])
    )
    $sky.append($testStarImg)

  $sky.hide()
  $('#rectangle').empty()
  $('#rectangle').append($sky)

  $sky.fadeIn(fadeDuration: FADE_DURATION)


# INITIALIZATION
@initTask = ->
  tabcat.task.start(trackViewport: true)

  tabcat.ui.turnOffBounce()

  $(->
    tabcat.ui.requireLandscapeMode($('#task'))
    tabcat.ui.fixAspectRatio($('#rectangle'), ASPECT_RATIO)

    showTargetStars()
  )
