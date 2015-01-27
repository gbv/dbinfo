# makefile (GNU make) to build Debian package

PACKAGE=$(shell perl -nE 'say $$1 if /^Package:\s+(.+)/' < debian/control)
UC_PACKAGE=$(shell echo $(PACKAGE) | tr a-z A-Z)

# pandoc is not required unless manpage needs rebuild
PANDOC = $(shell which pandoc)
ifeq ($(PANDOC),)
  PANDOC = $(error pandoc is required but not installed)
endif

manpage: debian/$(PACKAGE).1
debian/$(PACKAGE).1: README.md
	grep -v '^\[!' $< | $(PANDOC) -s -t man -M title="$(UC_PACKAGE)(1) Manual" -o $@

local:
	carton install

debian-package: local manpage
	dpkg-buildpackage -b -us -uc -rfakeroot
	mv ../$(PACKAGE)_* .

debian-clean:
	fakeroot debian/rules clean
