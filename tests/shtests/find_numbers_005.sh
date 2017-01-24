#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/find_numbers
INPUT_CIFS='./tests/inputs/AMCSD/new ./tests/inputs/AMCSD/old'
#END DEPEND--------------------------------------------------------------------

find_numbers=${INPUT_SCRIPT}

${find_numbers} ${INPUT_CIFS} | sort
