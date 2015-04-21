#!/bin/bash

cif_molecule --p1 \
             --one-datablock-output \
             --use-morgan-fingerprints \
             --use-atom-classes \
             tests/inputs/2006528.cif
