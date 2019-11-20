#!/bin/sh

scripts/cif_molecule \
    -i \
    --max-polymer-atoms=200 \
    --max-polymer-span=1 \
    --merge-disorder-groups \
    tests/inputs/polymers/2018417.cif
