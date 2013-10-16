Das Datenbankverzeichnis unter <http://uri.gbv.de/database/> (kurz **dbinfo**)
fürt Informationen über Kataloge und andere Datenbanken die für den GBV
relevant sind zusammen und stellt diese Informationen als Linked Open Data zur
Verfügung.

# Übersicht der Webanwendung

Das Datenbankverzeichnis ist öffentlich unter <http://uri.gbv.de/database/>
verfügbar.^[Der Zugriff per HTTPS unter <https://uri.gbv.de/database/> ist
ebenfalls möglich, die URIs verwenden allerdings alle HTTP.] Im Wesentlichen
können folgende Informationen abgerufen werden:

* Liste aller Datenbankgruppen und Datenbanken unter
  <http://uri.gbv.de/database/>.

* Liste von Datenbanken jeder Datenbankgruppe (z.B. lokale Bibliothekskataloge
  mit dem Präfix `opac` unter <http://uri.gbv.de/database/opac>).

* Datenbankdetails (z.B. zum GVK mit dem Datenbankkürzel `gvk` unter
  <http://uri.gbv.de/database/gvk> und zum Katalog der UB Hildesheim mit
  dem Datenbankkürzel `opac-de-hil2` unter
  <http://uri.gbv.de/database/opac-de-hil2>).

## Abruf von Datenbankinformationen

Bei Aufruf einer URI im Browser wird eine HTML-Seite ausgeliefert. Mit dem
URL-Parameter `format` sowie per HTTP Content-Negotiation können folgende
RDF-Serialisierungen ausgewählt werden:^[Auf die Dopplung von URIs durch
Unterscheidung zwischen "Information Resources" und "Non-Information Resources"
wird geflissentlich verzichtet.]

 Format      Parameter        HTTP Accept header
--------    ---------------- ----------------------
 RDF/Turtle  format=ttl       text/turtle
 RDF/XM      format=rdfxml    application/rdf+xml
 RDF/JSON    format=json      application/rdf+json
 JSON        format=dbinfo    *kein RDF-Format*

Die verwendeten RDF-Ontologien sind unter
<http://uri.gbv.de/database/ontology.html> dokumentiert.

# Administration

Der Quellcode der Webanwendung liegt in einem git-Repository unter
<https://github.com/gbv/dbinfo>. Zur Installation wird daraus ein
Debian-Paket erstellt.

## Installation und Updates

Ein fertiges Debian-Paket kann direkt installiert werden:

    sudo dpkg install dbinfo_0.01_i386.deb

Zu beachten ist, dass das Paket für die selbe Rechner-Architektur (z.B. i386)
und Betriebssystem-Version (z.B. Ubuntu) gebaut sein sollte.

Die Installationsskripte legen einen Nutzer `dbinfo` sowie das Verzeichnis
`/srv/dbinfo` mit der Webanwendung und allen benötigten Libraries und das
Verzeichnis `/var/log/dbinfo` für Logdateien an.

## Verwendung aus dem Git-Repository

Siehe ...

## Lokaler Aufruf

Das Skript `run.sh` startet die Anwendung mit dem Starman-Webserver. Zum Testen
kann über den Parameter `-d` stattdessen Plackup ausgewählt werden.

# Software-Entwicklung

## Übersicht


Die Anwendung ist in Perl geschrieben. Benötigte CPAN-Module sind in der Datei
`cpanfiles` aufgeführt und werden mittels [carton] im Unterverzeichnis `local`
installiert.

[carton]: https://metacpan.org/module/Carton

## Voraussetzungen

Zur Weiterentwicklung der Webanwendung werden benötigt:

* Grundlegende Build-Tools (GNU make, C-Compiler etc.)
* Debian-Paket-Tools (devscripts und debhelper)
* git
* Perl (mind. 5.14)
* [carton] (mind. 1.0) und cpanm (mind. 1.6)

Die benötigten Programme lassen sich unter Ubuntu folgendermaßen installieren:

    sudo apt-get install build-essential devscripts debhelper git-core perl
    wget -O - http://cpanmin.us | sudo perl - --self-upgrade
    sudo cpanm Carton

## Unit-Tests

Im Verzeichnis `t/` befinden sich Unit-Tests. Das Skript `./test.sh`
vereinfacht die Ausführung mittels carton. Um vor jedem Commit zu testen,
empfiehlt sich folgendes Skript als ausführbare Datei `.git/hooks/pre-commit`.
Mit `git commit -n` lässt sich der Test zur Not übergehen:

    #!/bin/sh
    git stash -q --keep-index  # safe working copy
    ./test.sh; RESULT=$?       # run tests
    git stash pop -q           # restore working copy
    exit $RESULT

Die Datei `.travis.yml` enthält eine Konfiguration um nach einem git-push nach
GitHub alle Tests automatisch auf <https://travis-ci.org/gbv/Covers> laufen zu
lassen.

## Debugging

Zum Logging wird [Log::Contextual](https://metacpan.org/module/Log::Contextual) 
auf verschiedenen Ebenen verwendet. Die Umgebungsvariable `GBV_APP_COVERS_UPTO`
setzt die Ebene, ab der Nachrichten als Warnungen ausgegeben werden. Das
run-Skript setzt diese Variable über den Parameter `-l`, bspw.:

    ./run.sh -d -l trace

## Debian-Paket

Das Debian-Paket wird mit dem Skript `build-debian.pl` erstellt und befindet sich
anschließend im Verzeichnis `debuild`, von wo es mit `dpkg --install`
installiert werden kann.
