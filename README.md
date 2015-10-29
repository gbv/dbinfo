# NAME

dbinfo - GBV Datenbankverzeichnis

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

GBV Datenbankverzeichnis provides a Linked Open Data endpoint with RDF data in
several serialization forms. Serialization form can be controlled via content
negotiation or via query parameter `format` (set to `ttl`, `json`, `rdfxml`,
`jsonld` for RDF or `html` for HTML by default). The RDF vocabularies are
documented at a page accessible via <http://uri.gbv.de/database/ontology.html>.

A convenient data format for reuse outside of RDF applications is JSON-LD:

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
   "url": "https://gso.gbv.de/DB=2.910/",
   "srubase" : "http://sru.gbv.de/amb",
   "picabase" : "http://gsoapi.gbv.de/DB=2.910/",
   "openaccess" : false
}
```

The service further provides an OpenSearch Suggest AI at `/api/dbkey` to query
database prefixes:

```bash
curl http://uri.gbv.de/database/api/dbkey?id=opac-de-91
```

```json
[ "opac-de-91",
  ["opac-de-916"],
  ["Online-Katalog der Ostfalia Hochschule für angewandte Wissenschaften"],
  ["http://uri.gbv.de/database/opac-de-916"]
]
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

Restart is required after changes.

## Logging

Log files are located at `/var/log/dbinfo/`.

# CHANGES

see debian/changelog

# SEE ALSO

The source code of dbinfo is managed in a public git repository at
<https://github.com/gbv/dbinfo>. Please report bugs and feature request at
<https://github.com/gbv/dbinfo/issues>!

The Changelog is located in file `debian/changelog`.

Development guidelines are given in file `CONTRIBUTING.md`.
