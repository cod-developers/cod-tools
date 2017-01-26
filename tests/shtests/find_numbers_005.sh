#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/find_numbers
#END DEPEND--------------------------------------------------------------------

find_numbers=${INPUT_SCRIPT}

${find_numbers} ./tests/inputs/AMCSD/new ./tests/inputs/AMCSD/old | sort
