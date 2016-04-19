#!/bin/sh

cif_printout_Python tests/inputs/test-biblio-stray-vals.cif 2>&1 \
    | perl -lpe 's/^.*?(cif_printout_Python: )/$1/g'
