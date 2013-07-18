TABCAT_HOST ?= http://127.0.0.1:5984
PUSHED = .pushed-$(subst :,_,$(subst /,_,$(TABCAT_HOST)))

# CoffeeScript to compile into JavaScript
COFFEE_SRC = $(shell find . -name '*.coffee' -not -name '.\#*')
JS_TARGETS = $(patsubst %.coffee, %.js, $(COFFEE_SRC))

# Tasks to push to CouchDB as design documents
TASKS = $(patsubst %/kanso.json, %, $(wildcard tasks/*/kanso.json))
TASK_PUSHES = $(patsubst %, %/$(PUSHED), $(TASKS))

.PHONY: all
all: $(TASK_PUSHES)

.PHONY: clean
clean:
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

$(JS_TARGETS): %.js: %.coffee
	if which coffeelint; then coffeelint -q $<; fi
	coffee -c $<
