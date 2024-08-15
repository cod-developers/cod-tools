#!/bin/sh

set -ue

./cif2tsv \
    --header \
    --datablock-name \
    --filename \
    inputs/2000000.cif \
    inputs/7052868.cif \
    inputs/9007991.cif \
    #
