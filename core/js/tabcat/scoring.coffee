###
Copyright (c) 2014, Regents of the University of California
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
# Utilities for scoring performance on TabCAT tasks.
#
# This module may be accessed either from the browser, via
# TabCAT.Scoring, or from within CouchDB, with
# Scoring = require('js/tabcat/scoring')
Scoring = {}

if module?  # inside CouchDB
  _ = require('../vendor/underscore')._
  gauss = require('../vendor/gauss/gauss')

  module.exports = Scoring = {}
else  # inside browser
  @TabCAT ?= {}
  @TabCAT.Scoring = Scoring


# map from taskName to
taskNameToScorer = {}

# register a function to score a task. This function should take
# a single argument, the eventLog, and return scoring information.
Scoring.addTaskScorer = (taskName, scorer) ->
  taskNameToScorer[taskName] = scorer


# score a task, based on its eventLog
Scoring.scoreTask = (taskName, eventLog) ->
  scorer = taskNameToScorer[taskName]

  if not scorer?
    return null
  else
    return scorer(eventLog)
