#!/bin/sh

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/find_numbers
#END DEPEND--------------------------------------------------------------------

find_numbers=${INPUT_SCRIPT}

${find_numbers} ./tests/inputs/journal1 ./tests/inputs/journal2 | sort
