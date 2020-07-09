#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=tests/scripts/cif_printout_Python
INPUT_CIF=tests/inputs/test-biblio-stray-vals.cif

#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_CIF} 2>&1 \
    | perl -lpe 's/^.*?(cif_printout_Python: )/$1/g'
