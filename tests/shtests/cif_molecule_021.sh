#!/bin/sh

scripts/cif_molecule \
    -i \
    --p1 \
    --max-polymer-atoms=200 \
    --max-polymer-span=1 \
    --merge-disorder-groups \
    tests/inputs/polymers/1523050.cif
