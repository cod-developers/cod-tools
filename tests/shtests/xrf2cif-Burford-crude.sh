#!/bin/sh

set -ue

xrf2cif=./scripts/xrf2cif
CIF=./tests/inputs/Burford_2000_p152_crude.xrf

${xrf2cif} ${CIF}
