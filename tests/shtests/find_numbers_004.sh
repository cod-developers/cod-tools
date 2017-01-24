#!/bin/sh

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/find_numbers
INPUT_CIFS='./tests/inputs/formula2 ./tests/inputs/formula1'
#END DEPEND--------------------------------------------------------------------

find_numbers=${INPUT_SCRIPT}

${find_numbers} ${INPUT_CIFS} | sort
