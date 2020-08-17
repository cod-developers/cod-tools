#!/bin/sh

# This Shell test checks whether all of the scripts in scripts/ accept
# '--help' command line option and prints out some useful information.

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPTS=$(find scripts -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print | sort | xargs echo)

#END DEPEND--------------------------------------------------------------------

for i in ${INPUT_SCRIPTS}
do
    if ! grep -qlF '#!perl -w # --*- Perl -*--' ./$i || perl -c ./$i 2>/dev/null
    then
        HELP_MESSAGE=$(./$i --help </dev/null)
        if [ -n "${HELP_MESSAGE}" ]
        then
            echo "${HELP_MESSAGE}" | grep -q USAGE || echo "$i: No USAGE section"
            echo "${HELP_MESSAGE}" | grep -q OPTIONS || echo "$i: No OPTIONS section"
        else
            echo "$i: No --help message output"
        fi
    fi
done
