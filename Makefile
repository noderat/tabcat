# This just ties together other makefiles. The real logic is in:
#
# Makefile.common
# core/Makefile
# tasks/Makefile.task

# each task gets its own target (e.g. "line-orientation")
TASK_TARGETS = $(patsubst tasks/%/kanso.json, %, $(wildcard tasks/*/kanso.json))

.PHONY: all core tasks clean $(TASK_TARGETS)

all: core $(TASK_TARGETS)

core:
	@$(MAKE) -C core

tasks: $(TASK_TARGETS)

$(TASK_TARGETS): %:
	@if [ -e tasks/$@/Makefile ]; then $(MAKE) -C tasks/$@; else $(MAKE) -C tasks/$@ -f ../Makefile.task; fi

clean:
	@$(MAKE) -C core clean
	@for task in $(TASK_TARGETS); do if [ -e tasks/$$task/Makefile ]; then $(MAKE) -C tasks/$$task clean; else $(MAKE) -C tasks/$$task -f ../Makefile.task clean; fi done
	rm -f *~
