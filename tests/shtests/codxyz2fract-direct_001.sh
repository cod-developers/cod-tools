#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/codxyz2fract
INPUT_XYZ=tests/inputs/xyz/2000000.xyz
#END DEPEND--------------------------------------------------------------------

./tests/scripts/codxyz2fract-direct \
    --cell 8.243,10.368,11.497,111.64,107.94,93.45 \
    --float-format "%15.6f" \
    ${INPUT_XYZ}
