#!/bin/sh

set -ue

find_numbers=./cif_find_duplicates

${find_numbers} ./inputs/cod1 ./inputs/cod2 | sort
