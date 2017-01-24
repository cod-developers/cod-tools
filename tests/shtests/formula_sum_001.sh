#!/bin/sh
#
# Tests script functionality to read from STDIN.

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/formula_sum
#END DEPEND--------------------------------------------------------------------

formula_sum=${INPUT_SCRIPT}

echo "C2H5OH" | ${formula_sum}
