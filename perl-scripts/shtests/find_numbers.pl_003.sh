#!/bin/sh

set -ue

unset LANG
unset `printenv | grep LC_ | awk -F= '{print $1}'`

find_numbers=./find-numbers.pl

${find_numbers} ./inputs/formula1 ./inputs/formula2 | sort
