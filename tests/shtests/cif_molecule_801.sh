#!/bin/sh

scripts/cif_molecule \
    -i \
    --max-polymer-atoms=200 \
    --max-polymer-span=2 \
    tests/inputs/polymers/1000000.cif
