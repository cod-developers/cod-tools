#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_find_duplicates
#END DEPEND--------------------------------------------------------------------

set -ue

${INPUT_SCRIPT} ./tests/inputs/formula2 ./tests/inputs/formula1 | sort
