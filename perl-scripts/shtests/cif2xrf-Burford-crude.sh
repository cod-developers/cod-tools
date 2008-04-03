#!/bin/sh

set -ue

cif2xrf=./cif2xrf
CIF=./inputs/Burford_2000_p152_crude.cif

${cif2xrf} ${CIF}
