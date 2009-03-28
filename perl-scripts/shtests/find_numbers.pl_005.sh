#!/bin/sh

set -ue

unset LANG
unset LC_CTYPE

find_numbers=./find-numbers.pl

${find_numbers} ./inputs/AMCSD/new ./inputs/AMCSD/old | sort
