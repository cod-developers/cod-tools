#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_diff

#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} --compare-numeric _tag \
    <(echo 'data_A1 _tag 123(4)') <(echo 'data_B1 _tag 100(5)')

${INPUT_SCRIPT} --compare-numeric _tag \
    <(echo 'data_A2 _tag 123(4)') <(echo 'data_B2 _tag 120(4)')
