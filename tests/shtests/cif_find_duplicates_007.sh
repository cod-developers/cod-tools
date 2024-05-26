#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_find_duplicates
#END DEPEND--------------------------------------------------------------------

set -ue

unset LANG
unset LC_CTYPE

${INPUT_SCRIPT} \
    ./tests/inputs/unparsable-formulae1 \
    ./tests/inputs/unparsable-formulae2 \
| sort
