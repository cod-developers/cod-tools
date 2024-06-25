#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_find_duplicates
#END DEPEND--------------------------------------------------------------------

set -ue

${INPUT_SCRIPT} ./tests/inputs/journal1 ./tests/inputs/journal2 | sort
