#! /bin/sh

# This Shell test attempts to parse the command line options from the
# script and its help in order to locate non-described and non-existing
# command line options.

for i in $(find scripts -maxdepth 1 -name \*~ -prune -o -type f -a -executable -print | sort)
do
    SCRIPT_TYPE=''
    if grep -qlF '#!perl -w # --*- Perl -*--' $i; then
        SCRIPT_TYPE='perl'
    elif grep -qlE '#!\s*/bin/sh' $i; then
        SCRIPT_TYPE='sh'
    elif grep -qlE '#!\s*/bin/bash' $i; then
        SCRIPT_TYPE='bash'
    elif grep -qlE '#!\s*/usr/bin/python' $i; then
        SCRIPT_TYPE='python'
    else
        echo "$i:: WARNING, could not determine the interpreter for the script."
    fi

    ./$i --help </dev/null 2>/dev/null \
        | ./tools/check_option_descriptions $i $SCRIPT_TYPE
done
