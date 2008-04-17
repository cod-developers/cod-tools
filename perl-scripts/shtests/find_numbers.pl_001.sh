#!/bin/sh

set -ue

find_numbers=./find-numbers.pl

${find_numbers} ./inputs/cod1 ./inputs/cod2 | sort
