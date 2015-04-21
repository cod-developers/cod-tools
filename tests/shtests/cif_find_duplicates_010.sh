#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

find_numbers=./scripts/cif_find_duplicates

${find_numbers} \
    --max-cell-length-diff 0.0001 \
    --max-cell-angle-diff 0.01 \
    tests/inputs/close-cells/new \
    tests/inputs/close-cells/cod \
| sort
