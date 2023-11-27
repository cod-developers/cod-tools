#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif2rdf
INPUT_CIF=tests/inputs/cif2rdf/2000000.cif

#END DEPEND--------------------------------------------------------------------

#**
#* Tests the way the 'cif2rdf' script handles the '--columns' option when
#* the option values are separated using a space symbol instead of a comma.
#**

set -ue

${INPUT_SCRIPT} ${INPUT_CIF} --columns "year doi alpha beta gamma a b c"
