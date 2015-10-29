MAINSRC:=lib/App/DBInfo.pm
CONTROL:=debian/control

# parse debian control file and changelog
C:=(
J:=)
PACKAGE:=$(shell perl -ne 'print $$1 if /^Package:\s+(.+)/;' < $(CONTROL))
ARCH   :=$(shell perl -ne 'print $$1 if /^Architecture:\s+(.+)/' < $(CONTROL))
DEPENDS:=$(shell perl -ne '\
	next if /^\#/; $$p=(s/^Depends:\s*/ / or (/^ / and $$p));\
	s/,|\n|\([^$J]+\)//mg; print if $$p' < $(CONTROL))
VERSION:=$(shell perl -ne '/^.+\s+[$C](.+)[$J]/ and print $$1 and exit' < debian/changelog)
RELEASE:=${PACKAGE}_${VERSION}_${ARCH}.deb

# show configuration
info:
	@echo "Release: $(RELEASE)"
	@echo "Depends: $(DEPENDS)"

version:
	@perl -p -i -e 's/^our\s+\$$VERSION\s*=.*/our \$$VERSION="$(VERSION)";/' $(MAINSRC)
	@perl -p -i -e 's/^our\s+\$$NAME\s*=.*/our \$$NAME="$(PACKAGE)";/' $(MAINSRC)

# build documentation
PANDOC = $(shell which pandoc)
ifeq ($(PANDOC),)
  PANDOC = $(error pandoc is required but not installed)
endif

docs: README.md
	cd doc; make dbinfo.pdf

manpage: debian/$(PACKAGE).1
debian/$(PACKAGE).1: README.md $(CONTROL)
	@grep -v '^\[!' $< | $(PANDOC) -s -t man -o $@ \
		-M title="$(shell echo $(PACKAGE) | tr a-z A-Z)(1) Manual" -o $@

# build Debian package
package: debian/$(PACKAGE).1 version tests
	dpkg-buildpackage -b -us -uc -rfakeroot
	mv ../$(PACKAGE)_$(VERSION)_*.deb .

# install required toolchain and Debian packages
dependencies:
	apt-get install fakeroot dpkg-dev debhelper
	apt-get install pandoc libghc-citeproc-hs-data 
	apt-get install $(DEPENDS)

# install required Perl packages
local: cpanfile
	cpanm -l local --skip-satisfied --installdeps --notest .

# run locally
run: local
	plackup -Ilib -Ilocal/lib/perl5 -r app.psgi

# check sources for syntax errors
code:
	@find lib -iname '*.pm' -exec perl -c -Ilib -Ilocal/lib/perl5 {} \;

# run tests
tests: local
	PLACK_ENV=tests prove -Ilocal/lib/perl5 -l -v
