#!/bin/sh

scripts/cif_molecule \
    --max-polymer-atoms=200 \
    --max-polymer-span=1 \
    tests/inputs/frameworks-synthetic-P432.cif
