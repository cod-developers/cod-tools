#!/bin/sh

set -ue

cif_split=./scripts/cif_split_primitive

CIF=./tests/inputs/Carbó_2002_p305_crude.cif

BASENAME="`basename $0 .sh`"

TMP_DIR="./tmp-${BASENAME}"

mkdir ${TMP_DIR}

cp ${CIF} ${TMP_DIR}
cp ${cif_split} ${TMP_DIR}

(
    cd ${TMP_DIR}

    CIF_BASE="`basename ${CIF}`"
    script_base="`basename ${cif_split}`"

    ./${script_base} < ${CIF_BASE} || true

    rm ${CIF_BASE}
    rm ${script_base}
)

diff --exclude .svn -rs tests/outputs/split/${BASENAME} ${TMP_DIR}

rm -rf ${TMP_DIR}
