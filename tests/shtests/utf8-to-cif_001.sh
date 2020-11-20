#!/bin/sh
##
# Tests the way input from STDIN is handled.
##
set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/utf8-to-cif
INPUT_CIF=tests/inputs/utf8-to-cif/bibliographies-utf8.txt
#END DEPEND--------------------------------------------------------------------

cat ${INPUT_CIF} | ${INPUT_SCRIPT}
