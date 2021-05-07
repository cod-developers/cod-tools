#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_cod_numbers
INPUT_CIF=tests/inputs/cif_cod_numbers/cif/2238212.cif

#END DEPEND--------------------------------------------------------------------

set -ue

grep -v '^_journal_paper_doi' \
    ${INPUT_CIF} \
| ${INPUT_SCRIPT}
