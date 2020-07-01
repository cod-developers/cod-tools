#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MATRIX=tests/inputs/matrices/wikipedia4.mat
INPUT_TEST_SCRIPT=tests/scripts/gj_elimination
#END DEPEND--------------------------------------------------------------------

"${INPUT_TEST_SCRIPT}" "${INPUT_MATRIX}"
