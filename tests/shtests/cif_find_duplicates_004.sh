#!/bin/sh

set -ue

find_numbers=./scripts/cif_find_duplicates

${find_numbers} ./tests/inputs/formula2 ./tests/inputs/formula1 | sort
