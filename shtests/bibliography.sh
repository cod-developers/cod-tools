#!/bin/sh

set -ue

cif2ref=./cif2ref
CIF=./inputs/converted.cif
DIR=`dirname $0`
BIB=${DIR}/`basename $0 .sh`.txt

${cif2ref} ${CIF} ${BIB}
