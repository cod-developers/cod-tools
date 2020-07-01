#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_CIF_COD_NUMBERS=scripts/cif_cod_numbers
INPUT_CIF_SELECT=scripts/cif_select
INPUT_CIF=tests/inputs/2000135.cif

#END DEPEND--------------------------------------------------------------------

set -ue

${INPUT_CIF_SELECT} \
    --tags _chemical_formula_sum \
    --invert \
    ${INPUT_CIF} \
    | ${INPUT_CIF_COD_NUMBERS} --use-attached-hydrogens
