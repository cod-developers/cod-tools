#!/bin/sh

set -ue

xrf2cif=./xrf2cif
CIF=./inputs/Cottone_2002_p418_crude.xrf

${xrf2cif} ${CIF}
