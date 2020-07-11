#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_printout_Python
INPUT_CIF=tests/inputs/cif_printout_Python/cif1/7050234-non-ascii-text-field.cif

#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_CIF} 2>&1 \
    | perl -lpe 's/^.*?(cif_printout_Python: )/$1/g'
