# NAME

dbinfo - GBV database information

[![Build Status](https://travis-ci.org/gbv/dbinfo.svg)](https://travis-ci.org/gbv/coverdienst)

# SYNOPSIS

The application is automatically started as service, listening on port 6027.

    sudo service dbinfo {status|start|stop|restart}

# INSTALLATION

The application is packaged as Debian package and installed at
`/srv/dbinfo/`. Log files are located at `/var/log/coverdienst/`.

# CONFIGURATION

See `/etc/default/dbinfo` for basic configuration and `/etc/dbinfo` for
extended configuration files. Restart is needed after changes. 

# SEE ALSO

Source code at <https://github.com/gbv/dbinfo>
