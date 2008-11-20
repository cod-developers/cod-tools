#!/bin/sh

set -ue

find_numbers=./find-numbers.pl

${find_numbers} ./inputs/journal1 ./inputs/journal2 | sort
