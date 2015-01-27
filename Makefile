
# extract build information from control file and changelog
POPEN  :=(
PCLOSE :=)
PACKAGE:=$(shell perl -ne 'print $$1 if /^Package:\s+(.+)/;' < debian/control)
VERSION:=$(shell perl -ne 'print $$1 if /^.+\s+[$(POPEN)](.+)[$(PCLOSE)]/' < debian/changelog)
DEPENDS:=$(shell perl -ne 'print $$1 if /^Depends:\s+(.+)/;' < debian/control)
DEPLIST:=$(shell echo "$(DEPENDS)" | perl -pe 's/(\s|,|[$(POPEN)].+?[$(PCLOSE)])+/ /g')
ARCH   :=$(shell dpkg --print-architecture)
RELEASE:=${PACKAGE}_${VERSION}_${ARCH}.deb

info:
	@echo "Depends: $(DEPENDS)"
	@echo "Release: $(RELEASE)"

# install local Perl modules
local:
	carton install

# build documentation
PANDOC = $(shell which pandoc)
ifeq ($(PANDOC),)
  PANDOC = $(error pandoc is required but not installed)
endif

manpage: debian/control debian/$(PACKAGE).1
debian/$(PACKAGE).1: README.md
	grep -v '^\[!' $< | $(PANDOC) -s -t man -o $@ \
		-M title="$(shell echo $(PACKAGE) | tr a-z A-Z)(1) Manual" -o $@

# build Debian package
release-file: local manpage
	dpkg-buildpackage -b -us -uc -rfakeroot
	mv ../$(RELEASE) .

# do cleanup
debian-clean:
	fakeroot debian/rules clean

# install required Debian packages and Carton
dependencies:
	apt-get update -qq
	apt-get install fakeroot dpkg-dev $(DEPLIST)
	cpanm Carton
