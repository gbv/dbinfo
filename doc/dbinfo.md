Das Datenbankverzeichnis unter <http://uri.gbv.de/database/> führt
Informationen über Kataloge und andere Datenbanken die für den GBV relevant
sind zusammen und stellt diese Informationen als Linked Open Data zur
Verfügung. Diese Handbuch beschreibt die Nutzung, Administration und
Entwicklung der Webanwendung des Datenbankverzeichnis.

# Übersicht

Mit dem Datenbankverzeichnis (kurz auch **dbinfo**) werden unter
<http://uri.gbv.de/database/> (bzw. <https://uri.gbv.de/database/>) öffentlich
Informationen zu Datenbanken bereitgestellt, die für den GBV relevant sind. Das
Datenbanbankverzeichnis dient dabei ausdrücklichk *nicht* zur Verwaltung von
Datenbankinformationen sondern führt diese Informationen nur aus anderen
[Quellen](#quellen) zusammen. 

## Datenbanken

Jede Datenbank ist durch eine URI der Form 

    http://uri.gbv.de/database/xxx

identifiziert wobei statt `xxx` ein Datenbankkürzel (kurz auch **dbkey**)
steht. Hat das Datenbankkürzel die Form `aaa-bbb` so ist die Datenbank der
Gruppe mit dem Präfix `aaa` zugeordnet. Gruppenpräfixe bestehen immer aus
Kleinbuchstaben und Datenbankkürzel aus Kleinbuchstaben, Ziffern und dem
Minus-Zeichen. Unter der URI einer Gruppe kann die Liste aller Datenbank dieser
Gruppe und unter <http://uri.gbv.de/database/> die Liste aller Gruppen und
aller Datenbanken ohne Gruppe abgerufen werden.

Beispiele:

* Informationen zum Gemeinsamen Verbundkatalog mit dem Datenbankkürzel
  `gvk` stehen unter <http://uri.gbv.de/database/gvk>.

* Die Gruppe der lokalen Bibliothekskataloge mit dem Präfix `opac`
  steht unter <http://uri.gbv.de/database/opac>.

* Informationen zum Katalog der UB Hildesheim mit dem
  Datenbankkürzel `opac-de-hil2` in der Gruppe `opac` stehen unter
  <http://uri.gbv.de/database/opac-de-hil2>.

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
 JSON        format=dbinfo    *nicht unterstützt*

## Inhalte

Die verwendeten RDF-Ontologien sind unter
<http://uri.gbv.de/database/ontology.html> dokumentiert.

## Quellen

Die im Datenbankverzeichnis zusammengeführten Informationen stammen aus
folgenden Quellen:

* ...
* ... 

# Administration

Der Quellcode der Webanwendung liegt in einem nicht-öffentlichen git-Repository
unter <https://github.com/gbv/dbinfo>. Zur Installation wird daraus ein
Debian-Paket erstellt (interne Details siehe unter
[Software-Entwicklung](#software-entwicklung)).

Die Webanwendung läuft standardmäßig auf Port 6006 und muss über einen
Reverse-Proxy für <http://uri.gbv.de/database/> bereitgestellt werden.

## Installation und Updates

Ein fertiges Debian-Paket kann direkt installiert werden:

    sudo dpkg --install dbinfo_0.01_i386.deb

Zu beachten ist, dass das Paket für die selbe Rechner-Architektur (z.B. i386)
und Betriebssystem-Version (z.B. Ubuntu) gebaut sein sollte.

Mit `dpkg -s` bzw. `dpkg -L` kann überprüft werden ob und mit welchen Dateien
das Paket installiert ist. Die Installationsskripte legen einen Nutzer `dbinfo`
sowie das Verzeichnis `/srv/dbinfo` mit der Webanwendung und allen benötigten
Libraries und das Verzeichnis `/var/log/dbinfo` für Logdateien an. Zum
vollständigen entfernen der Anwendung:

    sudo dpkg --purge dbinfo

## Starten und Überprüfen

Zum Starten wird [upstart] verwendet, so dass sich die Webanwendung
folgendermaßen starten und stoppen lässt:

    sudo start dbinfo
    sudo stop dbinfo

Zusätzlich werden folgende Aufrufe unterstützt, um zu überprüfen ob die
Webanwendung läuft, um ihre Konfiguration neu zu laden bzw. um sie neu zu
starten:

    status dbinfo
    sudo restart dbinfo   # erzeugt neuen Prozess
    sudo reload dbinfo    # behält Prozess bei

## Logdateien

Beim Start der Anwendung erfolgt durch upstart ein Eintrag in der Logdatei
`/var/log/upstart/dbinfo.log`. Zugriffe werden unter
`/var/log/dbinfo/access.log` geloggt, wobei IP-Adressen von VZG-Rechnern
(127.0.0.1,193.174.240.0/24,195.37.139.0/24) erkannt werden wenn sie als Proxy
fungieren.

# Software-Entwicklung

## Übersicht

Die Anwendung ist in Perl geschrieben. Benötigte CPAN-Module sind in der Datei
`cpanfiles` aufgeführt und werden mittels [carton] im Unterverzeichnis `local`
installiert. Die genauen Versionen der verwendeten CPAN-Module sind in der
Datei `cpanfiles.snapshot` festgelegt.

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

## Lokaler Aufruf

Das Skript `run.sh` startet die Anwendung mit dem Starman-Webserver. Zum Testen
kann über den Parameter `-d` stattdessen Plackup ausgewählt werden.

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

Zum Logging wird [Log::Contextual] auf verschiedenen Ebenen verwendet. Die
Umgebungsvariable `GBV_APP_COVERS_UPTO` setzt die Ebene, ab der Nachrichten als
Warnungen ausgegeben werden. Das run-Skript setzt diese Variable über den
Parameter `-l`, bspw.:

    ./run.sh -d -l trace

## Debian-Paket

Das Debian-Paket wird mit dem Skript `build-debian.pl` durch Aufruf von `make
debian` erstellt und befindet sich anschließend im Verzeichnis `debuild`, von
wo es mit `dpkg --install` installiert werden kann. Die Versionsnummer wird aus
dem jeweils letzten Git-Tag der Form `v0.00` übernommen - es ist deshalb
notwendig beim Updaten eines Repository-Klons die Tags ebenfalls zu übernehmen.

    git pull origin master --tags
    make debian

[carton]: https://metacpan.org/module/Carton
[upstart]: http://upstart.ubuntu.com/
[Log::Contextual]: https://metacpan.org/module/Log::Contextual 

