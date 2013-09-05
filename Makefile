# This mostly ties together other makefiles. Most of the interesting stuff is in
# core/Makefile and tasks/Makefile.default
include Makefile.vars  # $(TABCAT_HOST) and $(PUSHED)

# each task gets its own target (e.g. "line-orientation")
TASK_TARGETS = $(patsubst tasks/%/kanso.json, %, $(wildcard tasks/*/kanso.json))
TASK_MAKEFILES = $(patsubst %, tasks/%/Makefile, $(TASK_TARGETS))

# tabcat config. this needs to not 404 for offline manifest to work
DEFAULT_CONFIG = config-default.json
CONFIG_URL = $(TABCAT_HOST)/tabcat-data/config

# offline manifest
KANSO_FILES = core/kanso.json $(wildcard tasks/*/kanso.json)
MANIFEST = cache.manifest
MANIFEST_DEPS = $(shell scripts/json-ls /attachments $(KANSO_FILES))
MANIFEST_URL = $(TABCAT_HOST)/tabcat/offline/$(MANIFEST)

.PHONY: all core tasks clean $(TASK_TARGETS)

all: core $(TASK_TARGETS) $(PUSHED)

core:
	$(MAKE) -C core

tasks: $(TASK_TARGETS)

$(TASK_TARGETS): %: tasks/%/Makefile
	$(MAKE) -C tasks/$@

# no real magic here; just symlink to Makefile.default if the task doesn't
# have its own Makefile
$(TASK_MAKEFILES): %:
	if [ ! -e $@ ]; then cd $(@D); ln -s ../Makefile.default Makefile; fi

$(MANIFEST): scripts/make-manifest $(KANSO_FILES) $(MANIFEST_DEPS)
	$< $(KANSO_FILES) > $@.tmp
	mv -f $@.tmp $@

# create the config file, if it exists, and upload the manifest
$(PUSHED): $(DEFAULT_CONFIG) $(MANIFEST)
	scripts/put-default $(DEFAULT_CONFIG) $(CONFIG_URL)
	scripts/force-put $(MANIFEST) $(MANIFEST_URL) text/cache-manifest
	touch $@

clean:
	$(MAKE) -C core clean
	for task in $(TASK_TARGETS); do if [ -e tasks/$$task/Makefile ]; then $(MAKE) -C tasks/$$task clean; else $(MAKE) -C tasks/$$task -f ../Makefile.task clean; fi done
	rm -f *~
