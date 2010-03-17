#!/bin/sh

set -ue

PATH=.:${PATH}

cif_codify=./cif_CODify
CIF=./inputs/1000000.cif

${cif_codify} ${CIF} --dont-use-datablocks-without-coordinates
