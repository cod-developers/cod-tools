#!/bin/sh

set -ue

cif2xrf=./scripts/cif2xrf
CIF=./tests/inputs/Burford_2000_p152_crude.cif

${cif2xrf} ${CIF}
