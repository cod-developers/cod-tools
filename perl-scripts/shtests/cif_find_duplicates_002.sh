#!/bin/sh

set -ue

find_numbers=./cif_find_duplicates

${find_numbers} ./inputs/journal1 ./inputs/journal2 | sort
