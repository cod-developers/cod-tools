#!/bin/bash

set -ue

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_tcod_tree
#END DEPEND--------------------------------------------------------------------

cif_tcod_tree=${INPUT_SCRIPT}
cwd=$(pwd)

BASENAME="`basename $0 .sh`"

set +ue

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

set -ue

mkdir ${TMP_DIR}

${cif_tcod_tree} --out ${TMP_DIR} <<END || true
data_tcod_cif
loop_
  _tcod_computation_step
  _tcod_computation_command
1
'cat test.cif'
loop_
  _tcod_file_id
  _tcod_file_URI
  _tcod_file_md5sum
  _tcod_file_name
0
file://${cwd}/tests/inputs/tcod-crafted.cif 
1eedf6b0f26288adfc8d440de7468d32
test.cif
END

find ${TMP_DIR} | LC_ALL=C sort

set -x

cat ${TMP_DIR}/main.sh || true

set +x

rm -rf ${TMP_DIR}
