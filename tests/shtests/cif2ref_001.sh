#!/bin/sh

set -ue

cif2ref=./scripts/cif2ref
CIF=./tests/inputs/converted.cif
BIB=./tests/inputs/bibliography.txt

${cif2ref} ${CIF} ${BIB}
