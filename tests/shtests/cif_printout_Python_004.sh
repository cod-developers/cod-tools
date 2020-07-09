#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=tests/scripts/cif_printout_Python
INPUT_CIF=tests/inputs/DDLm_3.11.09.dic

#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_CIF}
