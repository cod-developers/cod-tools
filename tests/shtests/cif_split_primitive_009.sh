#!/bin/sh

set -ue

cif_split=./scripts/cif_split_primitive

CIF=./tests/inputs/2-entries-AMCSD-cifdata.cif

BASENAME="`basename $0 .sh`"

TMP_DIR="./tmp-${BASENAME}"

mkdir ${TMP_DIR}

cp ${CIF} ${TMP_DIR}
cp ${cif_split} ${TMP_DIR}

(
    cd ${TMP_DIR}

    CIF_BASE="`basename ${CIF}`"
    CIF_CORE="`basename ${CIF} .cif`"

    script_base="`basename ${cif_split}`"

    mkdir ${CIF_CORE}

    ./${script_base} --output-dir=${CIF_CORE}/ < ${CIF_BASE} || true

    rm ${CIF_BASE}
    rm ${script_base}
)

diff --exclude .svn -rs tests/outputs/split/${BASENAME} ${TMP_DIR}

rm -rf ${TMP_DIR}
