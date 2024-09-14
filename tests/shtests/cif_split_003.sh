#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_split
INPUT_CIF=tests/inputs/Burford_2000_p152_crude.cif
#END DEPEND--------------------------------------------------------------------

BASENAME=$(basename "$0" .sh)

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

set -ue

mkdir "${TMP_DIR}"

${INPUT_SCRIPT} < ${INPUT_CIF} -o "${TMP_DIR}" 2>&1 | xargs -n1 basename || true

# shellcheck disable=SC2016
find "${TMP_DIR}" -name \*.cif | sort | xargs perl -n -e 'print "$ARGV: $_"'

rm -rf "${TMP_DIR}"
