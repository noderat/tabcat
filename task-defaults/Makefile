# Copyright (c) 2013-2014, Regents of the University of California.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   1. Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# The default makefile for tasks, if they don't have their own Makefile

include ../../Makefile.common  # $(TABCAT_HOST) and $(PUSHED)

# generated/symlinked files for scoring
SCORING_COFFEE_SRC = ./scoring/app.coffee ./scoring/scoring.coffee
SCORING_SYMLINKS = scoring/app.coffee scoring/kanso.json

# CoffeeScript to compile into JavaScript
COFFEE_SRC = $(sort $(shell find . -name '*.coffee' -not -name '.*') $(SCORING_COFFEE_SRC))
COFFEE_JS = $(patsubst %.coffee, %.js, $(COFFEE_SRC))

# files kanso expects to push
KANSO_DEPS = $(shell $(SCRIPTS)/json-ls /attachments+/modules kanso.json)
DDOC_NAME = $(shell $(SCRIPTS)/json-ls name kanso.json)

.PHONY: all
all: $(PUSHED_DBS)
	@: # suppress "nothing to be done for "all" message

.PHONY: clean
clean:
	rm -f $(COFFEE_JS)
	rm -f .pushed-*
	rm -f design.json
	rm -f scoring/design.json
	find . -type l -and -not -path ./Makefile -delete
	find . -name '*~' -delete

# compiling COFFEE_JS
$(COFFEE_JS): %.js: %.coffee
	coffee -c $<
	if which coffeelint; then coffeelint -q $<; fi

# task, for "tabcat" DB
$(PUSHED)_tabcat: design.json
	$(SCRIPTS)/force-put $< $(TABCAT_HOST)/tabcat/_design/$(DDOC_NAME)
	touch $@

design.json: kanso.json $(KANSO_DEPS)
	kanso install
	kanso show > $@

# scoring code, for "tabcat-data*" DBs
$(PUSHED_DATA_DBS): %: scoring/design.json
	$(SCRIPTS)/force-put $< $(patsubst $(PUSHED)_%,$(TABCAT_HOST)/%, $@)/_design/$(DDOC_NAME)
	touch $@

scoring/design.json: scoring/kanso.json scoring/app.js scoring/scoring.js scoring/js ../../core/js/tabcat/scoring.js
	mkdir -p $(@D)
	cd $(@D); kanso install
	cd $(@D); kanso show > $(@F)

$(SCORING_SYMLINKS): %:
	mkdir -p $(@D)
	ln -sf ../../../task-defaults/$@ $@

# scoring.coffee can be an empty file
scoring/scoring.coffee:
	mkdir -p $(@D)
	touch $@

scoring/js:
	mkdir -p $(@D)
	ln -sfh ../../../core/js $@


# optionally, pack all the JS code into a single file, js/task.js.
# (include js/task.js in kanso.json to activate this)
#
# You will still have to include ../core/js/tabcat.js separately because
# it's big enough (currently, 290K) that we don't want to duplicate it.

ifeq (,$(wildcard js/task.coffee))  # handle js/task.coffee normally
TASK_JS = scoring/scoring.js $(filter ./js/%,$(COFFEE_JS))
js/task.js: $(TASK_JS)
	cat $^ > $@
endif
