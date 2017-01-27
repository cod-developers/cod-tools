#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------

INPUT_CIF2JSON=scripts/cif2json
INPUT_CIFFILTER=scripts/cif_filter
INPUT_CIF2COD=scripts/cif2cod
INPUT_CIF=tests/inputs/2000000-trimmed.cif

#END DEPEND--------------------------------------------------------------------

${INPUT_CIF2JSON} ${INPUT_CIF} \
    | ${INPUT_CIFFILTER} --json \
    | ${INPUT_CIF2COD} --json-input
