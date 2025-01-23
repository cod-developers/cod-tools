#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_split_primitive
INPUT_CIF=tests/inputs/Carbó_2002_p305_crude.cif
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
ln -s $(realpath src) "${TMP_DIR}"

(
    cd "${TMP_DIR}"

    CIF_BASE=$(basename ${CIF})
    script_base=$(basename ${cif_split})

    ./"${script_base}" "${CIF_BASE}" || true

    rm "${CIF_BASE}"
    rm "${script_base}"
    rm src
)

diff --exclude .svn -rs tests/outputs/split/"${BASENAME}" "${TMP_DIR}" || true

rm -rf "${TMP_DIR}"
