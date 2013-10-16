# main div's aspect ratio (pretend we're on an iPad)
ASPECT_RATIO = 4/3

# stars' centers can never be less than this many star diameters apart
MIN_STAR_DISTANCE = 2

# target stars' centers can never be more than this many star diameters apart
MAX_TARGET_STAR_DISTANCE = 4

# Distances distractor stars should be from target stars. They should
# also be at least this far from any other target stars and any stars
# currently displayed
DISTRACTOR_STAR_DISTANCES = [3, 2]

# how many star diameters high the sky div is
SKY_STAR_HEIGHT = 12
# how many star diameters wide the sky div is
SKY_STAR_WIDTH = SKY_STAR_HEIGHT * ASPECT_RATIO

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

# return x squared
sq = (x) ->
  x * x


# return the distance between two points, squared
distSq = ([x1, y1], [x2, y2]) ->
  sq(x2 - x1) + sq(y2 - y1)


# convert star-diameter coordinates to an image tag to add to the sky div
makeStarImg = ([x1, y1]) ->
  $img = $('<img>')

  $img.attr('class', 'star')
  $img.attr('src', STAR_IMG_PATH)

  left = ((x1 - STAR_IMG_WIDTH / 2) / SKY_STAR_WIDTH * 100) + '%'
  top = ((y1 - STAR_IMG_HEIGHT / 2) / SKY_STAR_HEIGHT * 100) + '%'
  $img.css(left: left, top: top)

  $img.attr('width', (STAR_IMG_WIDTH / SKY_STAR_WIDTH * 100) + '%')
  $img.attr('height', (STAR_IMG_HEIGHT / SKY_STAR_HEIGHT * 100) + '%')

  return $img


# INITIALIZATION
@initTask = ->
  tabcat.task.start(trackViewport: true)

  tabcat.ui.turnOffBounce()

  tabcat.ui.requireLandscapeMode($('#task'))

  $sky = $('<div></div>', class: 'sky')
  $sky.append(makeStarImg([5, 5]), makeStarImg([3, 8]))

  $('#task').append($sky)
  tabcat.ui.fixAspectRatio($sky, ASPECT_RATIO)
