#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

find_numbers=./cif_find_duplicates

${find_numbers} \
    ./inputs/unparsable-formulae1 \
    ./inputs/unparsable-formulae2 \
| sort
