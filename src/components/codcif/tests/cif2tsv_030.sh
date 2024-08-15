#!/bin/sh

set -ue

./cif2tsv \
    --header \
    --datablock-name \
    --filename \
    --tags _cell_length_a,_cell_length_b,_cell_length_c,_cod_depositor_comments \
    --csv-out \
    inputs/2000000.cif \
    inputs/7052868.cif \
    inputs/9007991.cif \
    #
