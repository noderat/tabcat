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

@TabCAT ?= {}
TabCAT.Clock = {}

# so we don't have to type window.localStorage in functions
localStorage = @localStorage

# remove encounter clock from local storage
TabCAT.Clock.clear = ->
  delete localStorage.clockLastStarted
  delete localStorage.clockOffset
  return

# get nominal time since start of encounter when clock was restarted (msec)
TabCAT.Clock.lastStarted = ->
  TabCAT.Clock.start()
  return parseInt(localStorage.clockLastStarted)

# milliseconds since start of encounter
TabCAT.Clock.now = ->
  # evaluate offset before $.now() to avoid negative timestamps when
  # clock is start()ed implicitly
  offset = TabCAT.Clock.offset()
  return $.now() - offset

# add this to TabCAT.Clock.now() to get the real timestamp (in msec)
TabCAT.Clock.offset = ->
  TabCAT.Clock.start()
  return parseInt(localStorage.clockOffset)

# Reset the clock. Optionally, specify the current time relative to
# start of encounter (in msec)
TabCAT.Clock.reset = (startAt) ->
  startAt ?= 0
  localStorage.clockLastStarted = startAt
  localStorage.clockOffset = $.now() - startAt
  return  # don't let people depend on return value

# Start the clock, if it's not already started
TabCAT.Clock.start = (startAt) ->
  if not (localStorage.clockLastStarted and localStorage.clockOffset)
    TabCAT.Clock.reset(startAt)
