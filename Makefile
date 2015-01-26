# makefile (GNU make) to build Debian package

PACKAGE=$(shell perl -nE 'say $$1 if /^Package:\s+(.+)/' < debian/control)
UC_PACKAGE=$(shell echo $(PACKAGE) | tr a-z A-Z)

# TODO: changelog besser automatisch erstellen
VERSION=$(shell git tag | sort -r | perl -nE '/^\d+(\.\d+)+$$/ && do {say; exit}')
AUTHOR=Jakob Voss <voss@gbv.de>

.PHONY: changes
changes: debian/changelog
debian/changelog:
	echo "$(PACKAGE) ($(VERSION)) stable; urgency=low" > debian/changelog
	echo "" >> debian/changelog
	git log --pretty=format:"  * %s" >> debian/changelog
	echo "" >> debian/changelog
	echo "" >> debian/changelog
	echo " -- $(AUTHOR)  $(TIMESTAMP)" >> debian/changelog


# pandoc is not required unless manpage needs rebuild
PANDOC = $(shell which pandoc)
ifeq ($(PANDOC),)
  PANDOC = $(error pandoc is required but not installed)
endif

manpage: debian/control debian/$(PACKAGE).1
debian/$(PACKAGE).1: README.md
	grep -v '^\[!' $< | $(PANDOC) -s -t man -M title="$(UC_PACKAGE)(1) Manual" -o $@

local:
	carton install

debian-package: local manpage changes
	dpkg-buildpackage -b -us -uc -rfakeroot
	mv ../$(PACKAGE)_* .

debian-clean:
	fakeroot debian/rules clean
