#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=./tests/scripts/codxyz2ortho-direct
INPUT_XYZ=tests/inputs/xyz/2000000-with-cell.fxyz
#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} ${INPUT_XYZ}
