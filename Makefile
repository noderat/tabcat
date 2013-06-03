# CoffeeScript to compile into JavaScript
COFFEE_SRC = $(shell find . -name '*.coffee')
JS_TARGETS = $(patsubst %.coffee, %.js, $(COFFEE_SRC))

# Tasks to push to CouchDB as design documents
TASKS = $(patsubst %/kanso.json, %, $(wildcard tasks/*/kanso.json))
TASK_PUSHES = $(patsubst %, %/.pushed, $(TASKS))

.PHONY: all
all: $(TASK_PUSHES)

.PHONY: js
js: $(JS_TARGETS)


$(TASK_PUSHES): %/.pushed: %/kanso.json .kansorc $(JS_TARGETS)
	cd $(@D); kanso install
	kanso push $(@D)
	touch $@

$(JS_TARGETS): %.js: %.coffee
	if which coffeelint; then coffeelint -q $<; fi
	coffee -c $<

# auto-create .kansorc if it exists
.kansorc:
	cp .kansorc.example .kansorc
