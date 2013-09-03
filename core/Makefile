include ../Makefile.common

# CoffeeScript to compile into JavaScript
COFFEE_SRC = $(shell find . -name '*.coffee' -not -name '.*')
COFFEE_JS = $(patsubst %.coffee, %.js, $(COFFEE_SRC))

TABCAT_COFFEE_SRC = $(wildcard js/tabcat/*.coffee)
TABCAT_COFFEE_JS = $(patsubst %.coffee, %.js, $(TABCAT_COFFEE_SRC))

VENDOR_JS = $(wildcard js/vendor/*.js)

# files kanso expects to push
KANSO_DEPS = $(shell node ../scripts/kanso-deps.js)

# url of TabCAT config. Offline manifest needs this to not 404.
TABCAT_CONFIG_URL = $(TABCAT_HOST)/tabcat-data/config

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
$(PUSHED): kanso.json $(KANSO_DEPS)
	kanso install
	kanso push $(TABCAT_HOST)/tabcat
	kanso push $(TABCAT_HOST)/tabcat-data
	curl -f $(TABCAT_CONFIG_URL) &> /dev/null || curl -X PUT -H "Content-Type: application/json" -d {} $(TABCAT_CONFIG_URL)
	touch $@

ifeq ($(TABCAT_DEBUG), 1)
# force rebuild of js/tabcat.js
.PHONY: js/tabcat.js
js/tabcat.js: $(VENDOR_JS) $(TABCAT_COFFEE_JS)
	cat $^ > $@
else
js/tabcat.js: $(VENDOR_JS) $(TABCAT_COFFEE_JS)
	uglifyjs $^ -c -o $@
endif

$(COFFEE_JS): %.js: %.coffee
	if which coffeelint; then coffeelint -q $<; fi
	coffee -c $<
