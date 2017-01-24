#!/bin/sh

set -ue

unset LANG
unset `printenv | grep LC_ | awk -F= '{print $1}'`

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/find_numbers
#END DEPEND--------------------------------------------------------------------

find_numbers=${INPUT_SCRIPT}

${find_numbers} ./tests/inputs/formula1 ./tests/inputs/formula2 | sort
