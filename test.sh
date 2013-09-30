#!/bin/bash

# run all unit tests in directory t/ with carton
if [ $# == 0 ]
then
    exec carton exec -- prove -Ilib t
fi

# run specific tests given as command line arguments
for file in "$@"
do
    carton exec -- perl -Ilib $file
done
