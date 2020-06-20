#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MATRIX=tests/inputs/matrices/v2.dat
INPUT_TEST_SCRIPT=tests/scripts/gj_elimination
#END DEPEND--------------------------------------------------------------------

# 'undef' as the first arguments means "take default zero cut-off
# value for the G-J elimination module":

"${INPUT_TEST_SCRIPT}" undef "${INPUT_MATRIX}"
