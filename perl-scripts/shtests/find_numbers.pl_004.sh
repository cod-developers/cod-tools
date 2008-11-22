#!/bin/sh

set -ue

find_numbers=./find-numbers.pl

${find_numbers} ./inputs/formula2 ./inputs/formula1 | sort
