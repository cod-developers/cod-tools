#!/bin/sh

set -ue

PATH=.:${PATH}

cif_codify=./scripts/cif_CODify
CIF=./tests/inputs/1000000.cif

${cif_codify} ${CIF} --dont-use-datablocks-without-coordinates
