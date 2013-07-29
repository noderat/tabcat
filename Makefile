# This just ties together other makefiles. The real logic is in:
#
# Makefile.common
# core/Makefile
# tasks/Makefile.task

# each task gets its own target (e.g. "line-orientation")
TASK_TARGETS = $(patsubst tasks/%/kanso.json, %, $(wildcard tasks/*/kanso.json))
TASK_MAKEFILES = $(patsubst %, tasks/%/Makefile, $(TASK_TARGETS))

.PHONY: all core tasks clean $(TASK_TARGETS)

all: core $(TASK_TARGETS)

core:
	$(MAKE) -C core

tasks: $(TASK_TARGETS)

$(TASK_TARGETS): %: tasks/%/Makefile
	$(MAKE) -C tasks/$@

# no real magic here; just symlink to Makefile.default if the task doesn't
# have its own Makefile
$(TASK_MAKEFILES): %:
	if [ ! -e $@ ]; then cd $(@D); ln -s ../Makefile.default Makefile; fi

clean:
	$(MAKE) -C core clean
	for task in $(TASK_TARGETS); do if [ -e tasks/$$task/Makefile ]; then $(MAKE) -C tasks/$$task clean; else $(MAKE) -C tasks/$$task -f ../Makefile.task clean; fi done
	rm -f *~
