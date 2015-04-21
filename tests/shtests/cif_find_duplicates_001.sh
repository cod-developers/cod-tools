#!/bin/sh

set -ue

find_numbers=./scripts/cif_find_duplicates

${find_numbers} ./tests/inputs/cod1 ./tests/inputs/cod2 | sort
