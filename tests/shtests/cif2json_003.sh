#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------

INPUT_CIF2JSON=scripts/cif2json
INPUT_CIF_CORRECT_TAGS=scripts/cif_correct_tags
INPUT_CIF2COD=scripts/cif2cod
INPUT_CIF1=tests/inputs/2000000-trimmed.cif
INPUT_CIF2=tests/inputs/cif2json/4303187-multiple-underscores.cif

#END DEPEND--------------------------------------------------------------------

${INPUT_CIF2JSON} ${INPUT_CIF1} ${INPUT_CIF2} \
    | ${INPUT_CIF_CORRECT_TAGS} --json \
    | ${INPUT_CIF2COD} --json-input --no-print-header
