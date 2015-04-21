#!/bin/sh

set -ue

PATH=.:${PATH}

cif_codify=./scripts/cif_CODify
CIF=./tests/inputs/1000000-no-header.cif

${cif_codify} ${CIF} \
    --dont-use-datablocks-without-coordinates
