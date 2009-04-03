#!/bin/sh

set -ue

find_numbers=./cif_find_duplicates

${find_numbers} ./inputs/formula2 ./inputs/formula1 | sort
