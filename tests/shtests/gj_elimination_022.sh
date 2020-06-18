#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MATRIX=tests/inputs/matrices/v2.dat
INPUT_TEST_SCRIPT=tests/scripts/gj_elimination
#END DEPEND--------------------------------------------------------------------

# The first argument ('8') specifies coefficient to multiply the
# machine epsilon to get the zero cut-off value for the G-J
# elimination procedure:

"${INPUT_TEST_SCRIPT}" 8 "${INPUT_MATRIX}"
