#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_printout_Python
INPUT_CIF=tests/inputs/cif_printout_Python/cif2/ddl.dic

#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_CIF}
