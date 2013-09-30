#!/bin/bash

WEBSERVER=starman
WEBSERVER_ARGS=

while getopts "dl:h?" opt; do
    case "$opt" in
        h|\?)
            echo "usage: $0 [-d ] [-l \$LEVEL] [--] [arguments]" >&2
            echo ""
            echo "  -d  plackup webserver, restarting"
            echo "  -l  set logging level"
            exit 0
            ;;
        l)
            export GBV_APP_URI_DATABASE_UPTO=$OPTARG
            ;;
        d)
    	    WEBSERVER=plackup
    	    WEBSERVER_ARGS=-r
            ;;
    esac
done
shift $((OPTIND-1)) # Shift off the options and optional --

exec carton exec -- $WEBSERVER -Ilib $WEBSERVER_ARGS $@ 
