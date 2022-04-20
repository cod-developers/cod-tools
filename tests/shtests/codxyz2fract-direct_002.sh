#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/codxyz2fract
INPUT_XYZ=tests/inputs/xyz/2000000-with-lattice.xyz
#END DEPEND--------------------------------------------------------------------

./tests/scripts/codxyz2fract-direct \
    ${INPUT_XYZ}
