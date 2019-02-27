#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_split
INPUT_CIF=tests/inputs/placeholder-values.cif

#END DEPEND--------------------------------------------------------------------

BASENAME="`basename $0 .sh`"

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

set -ue

mkdir ${TMP_DIR}

cat ${INPUT_CIF} ${INPUT_CIF} | ${INPUT_SCRIPT} -o ${TMP_DIR} || true

for i in $(find ${TMP_DIR} -name \*.cif | sort)
do
    cat $i | xargs -i echo "$i: {}"
done

rm -rf ${TMP_DIR}
