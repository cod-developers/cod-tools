#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

find_numbers=./cif_find_duplicates

${find_numbers} ./inputs/AMCSD/new ./inputs/AMCSD/old | sort
