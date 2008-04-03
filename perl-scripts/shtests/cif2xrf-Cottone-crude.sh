#!/bin/sh

set -ue

cif2xrf=./cif2xrf
CIF=./inputs/Cottone_2002_p418_crude.cif
BIB=./inputs/Cottone-bibliography.txt

${cif2xrf} ${CIF} ${BIB}
