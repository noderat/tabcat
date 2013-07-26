# This just calls all the other Makefiles. The real Makefile logic is in these files:
#
# Makefile.common
# core/Makefile
# tasks/Makefile.task
TASKS = $(patsubst %/kanso.json, %, $(wildcard tasks/*/kanso.json))
SUBDIRS = core $(TASKS)

.PHONY: all
all:
	@for subdir in $(SUBDIRS); do $(MAKE) -C $$subdir; done

.PHONY: clean
clean:
	@for subdir in $(SUBDIRS); do $(MAKE) -C $$subdir clean; done
	rm -f *~
