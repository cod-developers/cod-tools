#!/bin/sh

scripts/cif_molecule \
    --max-polymer-atoms=200 \
    --max-polymer-span=2 \
    -i \
    tests/inputs/polymers/3000024.cif
