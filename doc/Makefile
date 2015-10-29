TITLE   = GBV Datenbankverzeichnis
AUTHOR  = Jakob Voß, Verbundzentrale des GBV
NAME    = dbinfo

dbinfo.md: ../README.md ../debian/changelog
	sed -r 's!^see debian/changelog!./changelog2markdown!e' ../README.md > $@

include vzgspec/Makefile

LANGUAGE=ngerman
