#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./tests/scripts/codxyz2fract-direct
INPUT_XYZ=tests/inputs/xyz/2000000-with-lattice.xyz
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_XYZ}
