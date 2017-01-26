#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_find_duplicates

#END DEPEND--------------------------------------------------------------------

set -ue

unset LANG
unset `printenv | grep LC_ | awk -F= '{print $1}'`

${INPUT_SCRIPT} ./tests/inputs/formula1 ./tests/inputs/formula2 | sort
