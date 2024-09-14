#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_filter
INPUT_CIF=tests/inputs/pdCIF_struct-complete-bipartite.cif
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} --bibliography <(echo '<year>2000</year>') \
    ${INPUT_CIF}
