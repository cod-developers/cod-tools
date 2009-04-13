#!/bin/sh

set -ue

PATH=.:${PATH}

cif_codify=./cif_CODify
CIF=./inputs/1000000-no-header.cif

${cif_codify} ${CIF}
