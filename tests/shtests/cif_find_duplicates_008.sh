#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

find_numbers=./scripts/cif_find_duplicates

${find_numbers} \
    --check-sample-history \
    ./tests/inputs/sample-history/new \
    ./tests/inputs/sample-history/cod \
| sort
