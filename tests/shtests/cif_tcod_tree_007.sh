#!/bin/bash

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_tcod_tree
INPUT_CIF=tests/inputs/aiida_exported_gzipped.cif
#END DEPEND--------------------------------------------------------------------

cif_tcod_tree=${INPUT_SCRIPT}

CIF=${INPUT_CIF}

BASENAME="`basename $0 .sh`"

set +ue

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

set -ue

mkdir ${TMP_DIR}

perl -lpe 's/(_audit_creation_method)/loop_ $1 "AiiDA version 0.9.1"/' ${CIF} \
    | ${cif_tcod_tree} --out ${TMP_DIR} || true

find ${TMP_DIR} | sort

set -x

cat ${TMP_DIR}/main.sh || true

set +x

rm -rf ${TMP_DIR}
