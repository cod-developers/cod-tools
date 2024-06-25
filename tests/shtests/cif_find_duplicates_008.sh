#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_find_duplicates
#END DEPEND--------------------------------------------------------------------

set -ue

unset LANG
unset LC_CTYPE

${INPUT_SCRIPT} \
    --check-sample-history \
    ./tests/inputs/sample-history/new \
    ./tests/inputs/sample-history/cod \
| sort
