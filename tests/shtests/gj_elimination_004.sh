#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MATRIX=tests/inputs/matrices/mat3x4.dat
INPUT_TEST_SCRIPT=tests/scripts/gj_elimination
#END DEPEND--------------------------------------------------------------------

"${INPUT_TEST_SCRIPT}" "${INPUT_MATRIX}"
