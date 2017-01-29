#!/bin/sh

set -ue

./cifvalues \
    --tag _cell_length_a,_cell_length_b,_cell_length_c \
    inputs/2000000.cif
