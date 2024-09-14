#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_CIF2JSON=scripts/cif2json
INPUT_CIF_CORRECT_TAGS=scripts/cif_correct_tags
INPUT_JSON2CIF=scripts/json2cif
INPUT_CIF=tests/inputs/zq2107.cif
#END DEPEND--------------------------------------------------------------------

${INPUT_CIF2JSON} ${INPUT_CIF} \
    | ${INPUT_CIF_CORRECT_TAGS} --json \
    | ${INPUT_JSON2CIF}
