#!/bin/sh

set -ue

find_numbers=./scripts/find_numbers

${find_numbers} ./tests/inputs/journal1 ./tests/inputs/journal2 | sort
