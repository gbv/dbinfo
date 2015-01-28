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
put the service behind a reverse proxy to enable SSL and nice URLs!

# USAGE

GBV Datenbankverzeichnis provides a Linked Open Data endpoint with RDF data in
several serialization forms. The service further provides an OpenSearch Suggest
AI at `/api/dbkey` to query database prefixes.

# ADMINISTRATION

## Configuration

Config file `/etc/default/dbinfo` only contains basic server configuration
in form of simple key-values pairs:

* `PORT`    - port number (required, 6006 by default)
* `WORKERS` - number of parallel connections (required, 5 by default).

Additional configuration is placed in `/etc/dbinfo`.
Restart is required after changes. 

## Logging

Log files are located at `/var/log/dbinfo/`.

# SEE ALSO

The source code of dbinfo is managed in a public git repository at
<https://github.com/gbv/dbinfo>. Please report bugs and feature request at
<https://github.com/gbv/dbinfo/issues>!

The Changelog is located in file `debian/changelog`.

Development guidelines are given in file `CONTRIBUTING.md`.
