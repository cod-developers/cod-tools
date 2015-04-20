#!/bin/sh

# This Shell test checks whether all of the scripts in perl-scripts/ accept
# '--help' command line option and prints out some useful information.

for i in $(find . -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print)
do
    HELP=$(./$i --help </dev/null)
    if [ "$?" = 0 ]
    then
        echo "${HELP}" | grep -q USAGE || echo $i: No USAGE section
        echo "${HELP}" | grep -q OPTIONS || echo $i: No OPTIONS section
    fi
done
