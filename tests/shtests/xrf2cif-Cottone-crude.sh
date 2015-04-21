#!/bin/sh

set -ue

xrf2cif=./scripts/xrf2cif
CIF=./tests/inputs/Cottone_2002_p418_crude.xrf

${xrf2cif} ${CIF}
