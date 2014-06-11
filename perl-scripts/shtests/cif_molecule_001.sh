#!/bin/bash

if ! perl -MAtomClassifier -e 'exit 0' 2>/dev/null
then
    echo Test skipped
    exit 0
fi

cif_molecule --p1 \
             --one-datablock-output \
             --use-morgan-fingerprints \
             --use-atom-classes \
             inputs/2006528.cif
