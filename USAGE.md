# Übersicht

Das Datenbankverzeichnis unter <http://uri.gbv.de/database/> führt
Informationen über Kataloge und andere Datenbanken die für den GBV relevant
sind zusammen und stellt diese Informationen als Linked Open Data zur
Verfügung. Diese Handbuch beschreibt die Nutzung, Administration und
Entwicklung der Webanwendung des Datenbankverzeichnis.

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

 Format      Parameter         HTTP Accept header
--------    ----------------- ----------------------
 RDF/Turtle  `format=ttl`      text/turtle
 RDF/XM      `format=rdfxml`   application/rdf+xml
 RDF/JSON    `format=json`     application/rdf+json
 JSON        `format=dbinfo`   *nicht unterstützt*

## Inhalte

Die verwendeten RDF-Ontologien sind unter
<http://uri.gbv.de/database/ontology.html> dokumentiert.

## Quellen

Die im Datenbankverzeichnis zusammengeführten Informationen stammen aus
folgenden Quellen:

* ...
* ... 


