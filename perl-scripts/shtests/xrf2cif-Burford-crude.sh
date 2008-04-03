#!/bin/sh

set -ue

xrf2cif=./xrf2cif
CIF=./inputs/Burford_2000_p152_crude.xrf

${xrf2cif} ${CIF}
