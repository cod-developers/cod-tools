#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

find_numbers=./scripts/cif_find_duplicates

${find_numbers} \
    ./tests/inputs/unparsable-formulae1 \
    ./tests/inputs/unparsable-formulae2 \
| sort
