include ../Makefile.vars  # $(TABCAT_HOST) and $(PUSHED)

# CoffeeScript to compile into JavaScript
COFFEE_SRC = $(shell find . -name '*.coffee' -not -name '.*')
COFFEE_JS = $(patsubst %.coffee, %.js, $(COFFEE_SRC))

TABCAT_COFFEE_SRC = $(wildcard js/tabcat/*.coffee)
TABCAT_COFFEE_JS = $(patsubst %.coffee, %.js, $(TABCAT_COFFEE_SRC))

VENDOR_JS = $(wildcard js/vendor/*.js)

# files kanso expects to push
KANSO_DEPS = $(shell ../scripts/json-ls /attachments+/modules kanso.json)

.PHONY: all
all: $(PUSHED)
	@: # suppress "nothing to be done for "all" message

.PHONY: clean
clean:
	rm -f $(COFFEE_JS)
	rm -f js/tabcat.js js/tabcat.js
	rm -f .pushed-*
	find . -name '*~' -delete

# $(KANSO_DEPS) should include js/tabcat.js
#
# It's fine if we can't upload the config; we just want to ensure there is one.
$(PUSHED): kanso.json $(KANSO_DEPS) $(MANIFEST)
	kanso install
	kanso push $(TABCAT_HOST)/tabcat
	kanso push $(TABCAT_HOST)/tabcat-data
	touch $@

ifeq ($(TABCAT_DEBUG), 1)
# force rebuild of js/tabcat.js
.PHONY: js/tabcat.js
js/tabcat.js: $(VENDOR_JS) $(TABCAT_COFFEE_JS)
	cat $^ > $@
else
js/tabcat.js: $(VENDOR_JS) $(TABCAT_COFFEE_JS)
	uglifyjs $^ -c warnings=false -o $@
endif

$(COFFEE_JS): %.js: %.coffee
	if which coffeelint; then coffeelint -q $<; fi
	coffee -c $<
