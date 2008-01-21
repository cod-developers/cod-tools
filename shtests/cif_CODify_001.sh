#!/bin/sh

set -ue

cif_codify=./cif_CODify
CIF=./inputs/1000000.cif

${cif_codify} ${CIF}
