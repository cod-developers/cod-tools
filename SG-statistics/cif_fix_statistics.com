#!/bin/sh
#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
# This script was created automatically with:
# Id: mkcom 195 2010-03-11 10:21:36Z saulius 
#
# Processing a LOG file with 'grep'.
#**

TMP_DIR="${TMPDIR}"

setvar() { eval $1="'$3'"; }

set -ue

OUTPUT_DIR="./outputs"

#BEGIN DEPEND------------------------------------------------------------------

INPUT_LOG="$(echo $(ls -1 inputs/cod/cif/checks/*.log | grep -v '/make'))"

BASENAME="`basename $0 .com`"

OUTPUT_DAT="${OUTPUT_DIR}/${BASENAME}.dat"

#END DEPEND--------------------------------------------------------------------

test -z "${TMP_DIR}" && TMP_DIR="."
TMP_DIR="${TMP_DIR}/tmp-${BASENAME}-$$"
mkdir "${TMP_DIR}"

. ./paths.sh

set -x

grep -Eh 'temp|melting' ${INPUT_LOG} \
| grep '^/.*/perl-scripts/cif_validate:' \
| awk '{print $2}' \
| sort \
| uniq \
| sed -e 's,^../,inputs/cod/cif/,' \
| xargs cif_fix_values \
> /dev/null 2> ${OUTPUT_DAT}

ALL_LINES=$(wc -l < ${OUTPUT_DAT})
NOTE_LINES=$(grep "NOTE," ${OUTPUT_DAT} | wc -l)

echo Fixed ${NOTE_LINES} out of ${ALL_LINES} \
"("$(echo ${NOTE_LINES} ${ALL_LINES} | awk '{printf "%4.1f", $1*100/$2}')%")"

rm -rf "${TMP_DIR}"
