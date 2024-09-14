#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_split_primitive
INPUT_CIF=tests/inputs/2-entries-AMCSD-global.cif
#END DEPEND--------------------------------------------------------------------

BASENAME=$(basename "$0" .sh)

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

set -ue

cif_split=${INPUT_SCRIPT}

CIF=${INPUT_CIF}

mkdir "${TMP_DIR}"

cp ${CIF} "${TMP_DIR}"
cp ${cif_split} "${TMP_DIR}"

(
    cd "${TMP_DIR}"

    CIF_BASE=$(basename ${CIF})
    CIF_CORE=$(basename ${CIF} .cif)

    script_base=$(basename ${cif_split})

    mkdir "${CIF_CORE}"

    ./"${script_base}" --output-dir="${CIF_CORE}/" < "${CIF_BASE}" || true

    rm "${CIF_BASE}"
    rm "${script_base}"
)

diff --exclude .svn --exclude .gitignore -rs tests/outputs/split/"${BASENAME}" "${TMP_DIR}" || true

rm -rf "${TMP_DIR}"
