#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/molcif2sdf
INPUT_CIF=./tests/inputs/2228759-multiple-diacritics.cif
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_CIF}
