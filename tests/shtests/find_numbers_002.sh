#!/bin/sh

set -ue

find_numbers=./scripts/find-numbers

${find_numbers} ./tests/inputs/journal1 ./tests/inputs/journal2 | sort
