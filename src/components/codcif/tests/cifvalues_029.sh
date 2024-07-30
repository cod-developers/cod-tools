#!/bin/bash

set -ue

./cifvalues \
    --head \
    --filename \
    --always \
    --quote '"' \
    --sep , \
    --tags _chemical_formula_sum,_cell_length_a,_cell_length_b,_cell_length_c \
    inputs/2000000.cif \
    inputs/1004001-disorder.cif \
    inputs/1508696-long-text-field.cif \
    inputs/2000000.cif \
    inputs/4067640.cif \
    inputs/4318422.cif \
    inputs/4319975.cif \
    inputs/7052868.cif \
    inputs/9007991.cif \
    #
