#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_molecule
INPUT_CIF=tests/inputs/2006528.cif
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} --p1 \
                --one-datablock-output \
                --use-morgan-fingerprints \
                --use-atom-classes \
                ${INPUT_CIF}
