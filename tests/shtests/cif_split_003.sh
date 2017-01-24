#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_split
INPUT_CIF=tests/inputs/Burford_2000_p152_crude.cif

#END DEPEND--------------------------------------------------------------------

set -ue

BASENAME="`basename $0 .sh`"

TMP_DIR="./tmp-${BASENAME}"

mkdir ${TMP_DIR}

${INPUT_SCRIPT} < ${INPUT_CIF} -o ${TMP_DIR} 2>&1 | xargs -n1 basename || true

for i in $(find ${TMP_DIR} -name \*.cif | sort)
do
    cat $i | xargs -i echo "$i: {}"
done

rm -rf ${TMP_DIR}
