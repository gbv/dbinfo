.PHONY: clean purge git

GIT = $(shell which git)
ifeq ($(GIT),)
    GIT = $(error git is required but not installed)
endif

CARTON = $(shell which carton)
ifeq ($(CARTON),)
    GIT = $(error carton is required but not installed)
endif

git:
	@$(GIT) --version > /dev/null

deps:
	@$(CARTON) install --deployment

debian: git deps
	@./dpkg-build.pl

clean:
	@rm -rf debuild

purge: clean
