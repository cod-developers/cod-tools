#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/codcif2sdf
INPUT_CIF=./tests/inputs/2202388.cif
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_CIF}
