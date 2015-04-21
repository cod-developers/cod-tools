#!/bin/sh

set -ue

find_numbers=./scripts/cif_find_duplicates

${find_numbers} ./tests/inputs/journal1 ./tests/inputs/journal2 | sort
