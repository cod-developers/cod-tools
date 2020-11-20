#!/bin/sh
##
# Tests the way input from STDIN is handled.
##
set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif-to-utf8
INPUT_CIF=tests/inputs/cif-to-utf8/bibliographies-cif_1.1.txt
#END DEPEND--------------------------------------------------------------------

cat ${INPUT_CIF} | ${INPUT_SCRIPT} 
