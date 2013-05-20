# compile coffeescript into JS
COFFEE_SRC = $(shell find . -name '*.coffee')
JS_TARGETS = $(patsubst %.coffee, %.js, $(COFFEE_SRC))

all: $(JS_TARGETS)

$(JS_TARGETS): %.js: %.coffee
	coffee -c $<
