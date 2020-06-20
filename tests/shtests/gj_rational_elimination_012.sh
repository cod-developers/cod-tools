#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_TEST_SCRIPT=tests/scripts/gj_rational_elimination
INPUT_MATRIX=tests/inputs/matrices/wikipedia3.mat
#END DEPEND--------------------------------------------------------------------

"${INPUT_TEST_SCRIPT}" "${INPUT_MATRIX}"
