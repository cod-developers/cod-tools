#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=tests/scripts/cif_printout_Python
INPUT_CIF=tests/inputs/1000000.cif

#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_CIF}
