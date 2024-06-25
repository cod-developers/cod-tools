#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_find_duplicates
#END DEPEND--------------------------------------------------------------------

set -ue

unset LANG
unset LC_CTYPE

${INPUT_SCRIPT} \
    --max-cell-length-diff 0.0001 \
    --max-cell-angle-diff 0.01 \
    tests/inputs/close-cells/new \
    tests/inputs/close-cells/cod \
| sort
