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
    if ./$i --version </dev/null >/dev/null 2>&1
    then
        ./$i --version </dev/null | diff <(echo ${VERSION_STR}) >/dev/null - ||
        (
            echo $i:
            ./$i --version </dev/null | diff <(echo ${VERSION_STR}) -
        )
    else
        echo $i: No --version option
    fi
done
