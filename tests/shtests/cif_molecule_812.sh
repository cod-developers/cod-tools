#!/bin/sh

scripts/cif_molecule \
    --p1 \
    --max-polymer-atoms=200 \
    --max-polymer-span=1 \
    tests/inputs/discrete-molecules-I432.cif
