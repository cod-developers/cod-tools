#!/bin/sh

set -ue

find_numbers=./scripts/find_numbers

${find_numbers} ./tests/inputs/formula2 ./tests/inputs/formula1 | sort
