# Timestamps reveal PHI (date of encounter) so instead we store time since
# start of encounter, which is stored in the browser and persists across
# tasks.
#
# Most tasks will only call .now(). Generally, .reset() will be called
# at the start of an encounter (not a task), .clear() will be called at the
# end, and .lastStarted() will be included in standard task data
# (.offset() as well, if we are allowed to store PHI).
#
# If you need to re-open an encounter, call reset() with the last known
# timestamp for that session.

@tabcat = {}
tabcat.clock = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage

# remove encounter clock from local storage
tabcat.clock.clear = ->
  delete localStorage.clockLastStarted
  delete localStorage.clockOffset
  return

# get nominal time since start of encounter when clock was restarted (msec)
tabcat.clock.lastStarted = ->
  tabcat.clock.start()
  return parseInt(localStorage.clockLastStarted)

# milliseconds since start of encounter
tabcat.clock.now = ->
  # evaluate offset before $.now() to avoid negative timestamps when
  # clock is start()ed implicitly
  offset = tabcat.clock.offset()
  return $.now() - offset

# add this to tabcat.clock.now() to get the real timestamp (in msec)
tabcat.clock.offset = ->
  tabcat.clock.start()
  return parseInt(localStorage.clockOffset)

# Reset the clock. Optionally, specify the current time relative to
# start of encounter (in msec)
tabcat.clock.reset = (startAt) ->
  startAt ?= 0
  localStorage.clockLastStarted = startAt
  localStorage.clockOffset = $.now() - startAt
  return  # don't let people depend on return value

# Start the clock, if it's not already started
tabcat.clock.start = (startAt) ->
  if not (localStorage.clockLastStarted and localStorage.clockOffset)
    tabcat.clock.reset(startAt)
