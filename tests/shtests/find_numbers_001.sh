#!/bin/sh

set -ue

find_numbers=./scripts/find_numbers

${find_numbers} ./tests/inputs/cod1 ./tests/inputs/cod2 | sort
