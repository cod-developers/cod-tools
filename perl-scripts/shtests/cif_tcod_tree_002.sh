#!/bin/sh

set -ue

cif_tcod_tree=./cif_tcod_tree

CIF=./inputs/cif_tcod_tree_002.cif

BASENAME="`basename $0 .sh`"

TMP_DIR="./tmp-${BASENAME}"

mkdir ${TMP_DIR}

${cif_tcod_tree} ${CIF} --out ${TMP_DIR}

set -x

tree ${TMP_DIR}
cat ${TMP_DIR}/main.sh

set +x

rm -rf ${TMP_DIR}
