#!/bin/bash

# This Shell test checks whether all of the scripts in scripts/ accept
# '--version' command line option and prints out some useful information.

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPTS=$(find scripts -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print | sort | xargs echo)
VERSION_FILE=.version

#END DEPEND--------------------------------------------------------------------

VERSION=$(grep -v ^# ${VERSION_FILE})
VERSION_STR="cod-tools version ${VERSION}"

for i in ${INPUT_SCRIPTS}
do
    if ! grep -qlF '#!perl -w # --*- Perl -*--' ./$i || perl -c ./$i 2>/dev/null
    then
        VERSION_MESSAGE=$(./$i --version </dev/null 2>&1)
        if [ -n "${VERSION_MESSAGE}" ]
        then
            echo "${VERSION_MESSAGE}" | diff <(echo ${VERSION_STR}) >/dev/null - ||
            (
                echo "$i: ${VERSION_MESSAGE}" | diff <(echo ${VERSION_STR}) -
            )
        else
            echo "$i: No --version option output"
        fi
    fi
done
