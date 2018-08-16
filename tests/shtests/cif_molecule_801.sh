#!/bin/sh

scripts/cif_molecule \
    --max-polymer-atoms=200 \
    --max-polymer-span=2 -i \
    tests/inputs/polymers/1000000.cif \
| sed 's/-0;/0;/g; s/-0 *$/0/'
