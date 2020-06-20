#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MATRIX=tests/inputs/matrices/v1.dat
INPUT_TEST_SCRIPT=tests/scripts/gj_elimination
#END DEPEND--------------------------------------------------------------------

"${INPUT_TEST_SCRIPT}" "${INPUT_MATRIX}"
