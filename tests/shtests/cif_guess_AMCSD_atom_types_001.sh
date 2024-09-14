#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=scripts/cif_guess_AMCSD_atom_types
INPUT_CIF=tests/inputs/9015578.cif
#END DEPEND--------------------------------------------------------------------

# Check diagnostics when the generated data items are already present:

${INPUT_SCRIPT} ${INPUT_CIF} | ${INPUT_SCRIPT} > /dev/null
