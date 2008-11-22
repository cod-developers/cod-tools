#!/bin/sh

set -ue

find_numbers=./find-numbers.pl

${find_numbers} ./inputs/formula1 ./inputs/formula2 | sort
