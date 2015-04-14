#!/bin/sh

set -ue

cif_split=./cif_split

CIF=./inputs/Cottone_2002_p418_crude.cif

BASENAME="`basename $0 .sh`"

TMP_DIR="./tmp-${BASENAME}"

mkdir ${TMP_DIR}

${cif_split} < ${CIF} -o ${TMP_DIR} || true

for i in $(find ${TMP_DIR} -name \*.cif | sort)
do
    cat $i | xargs -i echo "$i: {}"
done

rm -rf ${TMP_DIR}
