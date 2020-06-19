#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MATRIX_1=tests/inputs/matrices/v3-head-1.dat
INPUT_MATRIX_2=tests/inputs/matrices/v3-head-2.dat
INPUT_TEST_SCRIPT=tests/scripts/gj_elimination
#END DEPEND--------------------------------------------------------------------

"${INPUT_TEST_SCRIPT}" "${INPUT_MATRIX_1}"
"${INPUT_TEST_SCRIPT}" "${INPUT_MATRIX_2}"
