# SYNOPSIS

The application is automatically started as service, listening on port 6006.

    sudo service dbinfo {status|start|stop|restart}

# INSTALLATION

The software is released as Debian package for Ubuntu 14.04 LTS. Other Debian
based distributions *might* work too. Releases can be found at
<https://github.com/gbv/dbinfo/releases>

To install required dependencies either use a package manager such as `gdebi`,
manually install dependencies (inspectable via `dpkg -I dbinfo_*.deb`):

    sudo dpkg -i ...                       # install dependencies
    sudo dpkg -i dbinfo_X.Y.Z_amd64.deb    # change X.Y.Z

After installation the service is available at localhost on port 6006. Better
put the service behind a reverse proxy to enable SSL and nice URLs! In the
following a reverse proxy mapping <http://uri.gbv.de/database/> to
<http://localhost:6006/> is assumed.

# USAGE

GBV Datenbankverzeichnis provides an overview of databases used by or provided
at VZG. Information about databases can be retrieved in RDF, JSON, and CSV.

## Database organization

Each database is identified by an URI with prefix <http://uri.gbv.de/database/>
followed by a database key (**dbkey**). Each dbkey consists of lowercase
letters (`a-z`), digits (`0-9`), and/or minus (`-`). The part before the first
minus, if given, identifies a database group. For instance:

* <http://uri.gbv.de/database/gvk>: dbkey `gvk`
* <http://uri.gbv.de/database/opac>: database group `opac`
* <http://uri.gbv.de/database/opac-de-hil2>: database `opac-de-hil2` 
  in group `opac`

Information about databases groups is encoded in SKOS and can be retrieved in
JSKOS (`format=jsold`). A list of all database groups can be retrieved at the
base URL:

* <http://uri.gbv.de/database/?format=jsonld>
* <http://uri.gbv.de/database/opac?format=jsonld>

## Database metadata

Information about databases can be retrieved in several RDF serialization forms
selecetd by HTTP content negotiation or via query parameter `format` (set to
`ttl`, `json`, `rdfxml`, `jsonld` for RDF, or `html` for HTML as default). The
RDF vocabularies are documented at a page accessible via
<http://uri.gbv.de/database/ontology.html>.  A convenient data format for reuse
outside of RDF applications is JSON-LD, specified at
<http://uri.gbv.de/database/dbinfo.jsonld>:

```bash
curl http://uri.gbv.de/database/amb?format=jsonld
```

```json
{
   "@context" : "http://uri.gbv.de/database/dbinfo.jsonld",
   "uri" : "http://uri.gbv.de/database/amb",
   "title" : {
      "de" : "Katalog der meereswissenschaftlichen Bibliotheken Deutschlands",
      "en" : "German Association of Marine Science Libraries and Information Centers Catalogue"
   },
   "dbkey" : "amb",
   ...
```

## Database statistics

ppend `.csv` to the Database URI to get statistics in CSV format.

## Suggest service

The service further provides an OpenSearch Suggest AI at `/api/dbkey` to query
database prefixes:

```bash
curl http://uri.gbv.de/database/api/dbkey?id=opac-de-91
```

```json
[ "opac-de-91",
  ["opac-de-916"],
  ["Online-Katalog der Ostfalia Hochschule für angewandte Wissenschaften"],
  ["http://uri.gbv.de/database/opac-de-916"] ]
```

# ADMINISTRATION

## Configuration

Config file `/etc/default/dbinfo` only contains basic server configuration
in form of simple key-values pairs:

* `PORT`    - port number (required, 6006 by default)
* `WORKERS` - number of parallel connections (required, 5 by default).

Additional configuration is placed in `/etc/dbinfo/config.yml` with
the following fields:

* `unapi` - base URL of unAPI config server to get databases from
* `proxy` - optional list of IPs or IP ranges the service can run behind
  (for logging the proxied request IPs instead of proxy IP).
* `base` - base URI (`http://uri.gbv.de/database/` by default)
* `stats` - directory to store statistics in (`/etc/dbinfo/stats` by default).

Restart is required after changes.

The script `/etc/dbinfo/diagram.r` is used to generate diagrams. It can be
adjusted locally, so updates to this script must be applied manually!

## Database Statistics

Database statistics are stored in `/etc/dbinfo/stats` (or in another directory
specified in configuration) in a CSV file for each database.  This directory
should be backed up to retain history data. Statistics is updated daily via cronjob
in `/etc/cron.daily/dbinfo`.

## Logging

Log files are located at `/var/log/dbinfo/`:

* `error.log` 
* `access.log`
* `mkstat.log`

# CHANGES

See `debian/changelog`.

# SEE ALSO

The source code of dbinfo is managed in a public git repository at
<https://github.com/gbv/dbinfo>. Please report bugs and feature request at
<https://github.com/gbv/dbinfo/issues>!

The Changelog is located in file `debian/changelog`.

Development guidelines are given in file `CONTRIBUTING.md`.
