#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------

INPUT_SCRIPT=scripts/cif_diff

#END DEPEND--------------------------------------------------------------------

${INPUT_SCRIPT} --compare-numeric _tag \
    <(echo 'data_A1 _tag 123(4)') <(echo 'data_B1 _tag 100(5)')

${INPUT_SCRIPT} --compare-numeric _tag \
    <(echo 'data_A2 _tag 123(4)') <(echo 'data_B2 _tag 120(4)')

${INPUT_SCRIPT} --compare-numeric _tag \
    <(echo 'data_A3 loop_ _tag 10(2) 10(2) 12(3) 10(1)') \
    <(echo 'data_B3 loop_ _tag 10(2) 11(2) 12(3) 20(1)')
