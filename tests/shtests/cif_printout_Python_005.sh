#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SCRIPT=tests/scripts/cif_printout_Python
#END DEPEND--------------------------------------------------------------------

cat <<END |
data_precisions
loop_
_tag
0.001e3(1) 0.001E3(1)
0.001e1(1) 0.001E1(1)
END
${INPUT_SCRIPT}
