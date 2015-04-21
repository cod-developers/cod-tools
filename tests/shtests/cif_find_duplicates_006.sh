#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

find_numbers=./scripts/cif_find_duplicates

BASENAME="`basename $0 .sh`"
TMP_DIR="./tmp-${BASENAME}"
mkdir ${TMP_DIR}

TMP_OUT="${TMP_DIR}/$(basename ${find_numbers}).out"
TMP_ERR="${TMP_DIR}/$(basename ${find_numbers}).err"

${find_numbers} ./tests/inputs/cifs-with-errors ./tests/inputs/cod-with-errors \
    > ${TMP_OUT} \
    2> ${TMP_ERR}

cat ${TMP_OUT}
cat ${TMP_ERR}

rm -rf ${TMP_DIR}
