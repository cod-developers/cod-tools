#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_find_duplicates
#END DEPEND--------------------------------------------------------------------

set -ue

${INPUT_SCRIPT} ./tests/inputs/cod1 ./tests/inputs/cod2 | sort
