#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_cod_numbers
INPUT_CIF=tests/inputs/cif_cod_numbers/cif/2238212.cif

#END DEPEND--------------------------------------------------------------------

set -ue

sed \
    's,10.1107/S1600536813014992,10.1107/S1600536813014XXX,' \
    ${INPUT_CIF} \
| ${INPUT_SCRIPT}
