#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_split
INPUT_CIF=tests/inputs/Carbó_2002_p305_crude.cif

#END DEPEND--------------------------------------------------------------------

BASENAME=$(basename "$0")

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}"

set -ue

mkdir "${TMP_DIR}"

${INPUT_SCRIPT} < ${INPUT_CIF} -o "${TMP_DIR}" || true

# shellcheck disable=SC2016
find "${TMP_DIR}" -name \*.cif | sort | xargs perl -n -e 'print "$ARGV: $_"'

rm -rf "${TMP_DIR}"
