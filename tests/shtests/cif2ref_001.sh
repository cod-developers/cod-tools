#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif2ref
INPUT_CIF=tests/inputs/converted.cif
INPUT_BIB=tests/inputs/bibliography.txt
#END DEPEND--------------------------------------------------------------------

set -ue

${INPUT_SCRIPT} ${INPUT_CIF} ${INPUT_BIB}
