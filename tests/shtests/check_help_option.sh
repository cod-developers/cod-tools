#!/bin/sh

# This Shell test checks whether all of the scripts in perl-scripts/ accept
# '--help' command line option and prints out some useful information.

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPTS=$(find scripts -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print | sort | xargs echo)

#END DEPEND--------------------------------------------------------------------

for i in ${INPUT_SCRIPTS}
do
    if ./$i --help </dev/null >/dev/null
    then
        ./$i --help | grep -q USAGE || echo $i: No USAGE section
        ./$i --help | grep -q OPTIONS || echo $i: No OPTIONS section
    fi
done
