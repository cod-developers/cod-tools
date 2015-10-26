#!/bin/sh
#
# Tests script functionality to read from STDIN.

set -ue

formula_sum=./scripts/formula_sum

echo "C2H5OH" | ${formula_sum}
