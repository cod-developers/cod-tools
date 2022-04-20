#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./scripts/codxyz2ortho
INPUT_XYZ=tests/inputs/xyz/2000000-with-cell.fxyz
#END DEPEND--------------------------------------------------------------------

./tests/scripts/codxyz2ortho-direct \
    ${INPUT_XYZ}
