#!/bin/sh

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/find_numbers
INPUT_CIFS='./tests/inputs/cod1 ./tests/inputs/cod2'
#END DEPEND--------------------------------------------------------------------

find_numbers=${INPUT_SCRIPT}

${find_numbers} ${INPUT_CIFS} | sort
