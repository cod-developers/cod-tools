#!/bin/sh

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/cif_tcod_tree
INPUT_CIF=./tests/inputs/aiida_exported.cif
#END DEPEND--------------------------------------------------------------------

cif_tcod_tree=${INPUT_SCRIPT}

CIF=${INPUT_CIF}

BASENAME="`basename $0 .sh`"

TMP_DIR="./tmp-${BASENAME}"

mkdir ${TMP_DIR}

${cif_tcod_tree} ${CIF} --out ${TMP_DIR} || true

set -x

tree ${TMP_DIR}
cat ${TMP_DIR}/main.sh || true

set +x

rm -rf ${TMP_DIR}
