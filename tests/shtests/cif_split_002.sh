#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_split
INPUT_CIF=tests/inputs/Carbó_2002_p305_crude.cif

#END DEPEND--------------------------------------------------------------------

BASENAME="`basename $0 .sh`"

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

set -ue

mkdir ${TMP_DIR}

${INPUT_SCRIPT} < ${INPUT_CIF} -o ${TMP_DIR} || true

for i in $(find ${TMP_DIR} -name \*.cif | sort)
do
    cat $i | xargs -i echo "$i: {}"
done

rm -rf ${TMP_DIR}
