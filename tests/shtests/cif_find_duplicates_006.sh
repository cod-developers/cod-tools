#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_find_duplicates

#END DEPEND--------------------------------------------------------------------

unset LANG
unset LC_CTYPE

find_numbers=${INPUT_SCRIPT}

BASENAME=$(basename "$0")

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"
mkdir "${TMP_DIR}"

set -ue

TMP_OUT="${TMP_DIR}/$(basename ${find_numbers}).out"
TMP_ERR="${TMP_DIR}/$(basename ${find_numbers}).err"

${find_numbers} --continue-on-errors \
    ./tests/inputs/cifs-with-errors ./tests/inputs/cod-with-errors \
    2> "${TMP_ERR}" \
    | sort > "${TMP_OUT}"

cat "${TMP_OUT}"
cat "${TMP_ERR}"

rm -rf "${TMP_DIR}"
