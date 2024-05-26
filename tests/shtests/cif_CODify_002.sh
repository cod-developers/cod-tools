#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_CODify
INPUT_CIF=tests/inputs/1000000-no-header.cif
#END DEPEND--------------------------------------------------------------------

set -ue

PATH=.:${PATH}

${INPUT_SCRIPT} ${INPUT_CIF} \
    --dont-use-datablocks-without-coordinates
