#!/bin/sh

set -ue

cif2xrf=./scripts/cif2xrf
CIF=./tests/inputs/Cottone_2002_p418_crude.cif
BIB=./tests/inputs/Cottone-bibliography.txt

${cif2xrf} ${CIF} ${BIB}
