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
