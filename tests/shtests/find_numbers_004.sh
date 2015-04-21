#!/bin/sh

set -ue

find_numbers=./scripts/find-numbers

${find_numbers} ./tests/inputs/formula2 ./tests/inputs/formula1 | sort
