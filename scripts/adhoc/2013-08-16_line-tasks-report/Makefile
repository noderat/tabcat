# Copyright (c) 2013, Regents of the University of California.
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

# CoffeeScript to compile into JavaScript
COFFEE_SRC = $(wildcard *.coffee)
COFFEE_JS = $(patsubst %.coffee, %.js, $(COFFEE_SRC))

NODE_MODULE_NAMES = csv JSONStream underscore
NODE_MODULES = $(patsubst %, node_modules/%, $(NODE_MODULE_NAMES))


.PHONY: all
all: $(COFFEE_JS) $(NODE_MODULES)

.PHONY: clean
clean:
	rm -f $(COFFEE_JS)
	rm -rf node_modules
	find . -name '*~' -delete

$(NODE_MODULES): %:
	npm install $(@F)


$(COFFEE_JS): %.js: %.coffee
	if which coffeelint; then coffeelint -q $<; fi
	coffee -c $<
