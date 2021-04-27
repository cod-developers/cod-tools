#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_hkl_check

#END DEPEND--------------------------------------------------------------------

cif_hkl_check=${INPUT_SCRIPT}

BASENAME="`basename $0 .sh`"
test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

mkdir "${TMP_DIR}"

cat > "${TMP_DIR}/test.cif" <<END
data_test
END

cat > "${TMP_DIR}/test.hkl" <<END
data_test
loop_
_refln_index_h
_refln_index_k
_refln_index_l
? ? ?
_shelx_hkl_checksum 12345
_shelx_hkl_file ''
END

${cif_hkl_check} "${TMP_DIR}/test.cif" "${TMP_DIR}/test.hkl"

rm -rf "${TMP_DIR}"
