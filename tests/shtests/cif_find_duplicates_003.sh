#!/bin/sh

set -ue

unset LANG
unset `printenv | grep LC_ | awk -F= '{print $1}'`

find_numbers=./scripts/cif_find_duplicates

${find_numbers} ./tests/inputs/formula1 ./tests/inputs/formula2 | sort
