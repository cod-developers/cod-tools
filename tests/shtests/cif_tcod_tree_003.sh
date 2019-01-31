#!/bin/bash

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_tcod_tree
INPUT_CIF=tests/inputs/aiida_exported_qp.cif
#END DEPEND--------------------------------------------------------------------

cif_tcod_tree=${INPUT_SCRIPT}

CIF=${INPUT_CIF}

BASENAME="`basename $0 .sh`"

set +ue

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

set -ue

mkdir ${TMP_DIR}

${cif_tcod_tree} ${CIF} --out ${TMP_DIR} || true

find ${TMP_DIR} | LC_ALL=C sort

set -x

cat ${TMP_DIR}/main.sh || true

set +x

rm -rf ${TMP_DIR}
