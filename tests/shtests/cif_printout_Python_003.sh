#!/bin/sh

cif_printout_Python tests/inputs/7050234-non-ascii-text-field.cif 2>&1 \
    | perl -lpe 's/^.*?(cif_printout_Python: )/$1/g'
