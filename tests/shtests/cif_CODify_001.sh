#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_CODify
INPUT_CIF=tests/inputs/cif_CODify/1000000.cif

#END DEPEND--------------------------------------------------------------------

set -ue

PATH=.:${PATH}

${INPUT_SCRIPT} ${INPUT_CIF} \
    --dont-use-datablocks-without-coordinates
