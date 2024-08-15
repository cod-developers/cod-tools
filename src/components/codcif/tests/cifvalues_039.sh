#!/bin/bash

set -ue

./cifvalues \
    --csv \
    --quote '"' \
    --tags _publ_author_name,_pd_block_id \
    inputs/1516218.cif \
    inputs/1518592.cif \
    #
