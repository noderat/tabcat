include Makefile.common

# CoffeeScript to compile into JavaScript
COFFEE_SRC = $(shell find tasks -name '*.coffee' -not -name '.*')
COFFEE_JS = $(patsubst %.coffee, %.js, $(COFFEE_SRC))

# Tasks to push to CouchDB as design documents
TASKS = $(patsubst %/kanso.json, %, $(wildcard tasks/*/kanso.json))
TASK_PUSHES = $(patsubst %, %/$(PUSHED), $(TASKS))

.PHONY: all
all: $(TASK_PUSHES)
	@$(MAKE) -C core all

.PHONY: clean
clean:
	$(MAKE) -C core clean
	rm -f $(JS_TARGETS)
	find . -name '.pushed-*' -delete
	find . -name '*~' -delete


.PHONY: js
js: $(JS_TARGETS)


$(TASK_PUSHES): %/$(PUSHED): %/kanso.json $(JS_TARGETS)
	cd $(@D); kanso install
	kanso push $(@D) $(TABCAT_HOST)/tabcat
	kanso push $(@D) $(TABCAT_HOST)/tabcat-data
	touch $@

$(COFFEE_JS): %.js: %.coffee
	if which coffeelint; then coffeelint -q $<; fi
	coffee -c $<
