#!/bin/sh

set -ue

cif_tcod_tree=./scripts/cif_tcod_tree

CIF=./tests/inputs/aiida_exported_qp.cif

BASENAME="`basename $0 .sh`"

TMP_DIR="./tmp-${BASENAME}"

mkdir ${TMP_DIR}

${cif_tcod_tree} ${CIF} --out ${TMP_DIR} || true

set -x

tree ${TMP_DIR}
cat ${TMP_DIR}/main.sh || true

set +x

rm -rf ${TMP_DIR}
