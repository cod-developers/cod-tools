#!/bin/sh

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/utf8-to-cif
INPUT_CIF=./tests/inputs/utf8.txt
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_CIF}
