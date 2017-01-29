#!/bin/sh

set -ue

./cifparse \
    --fix \
    --suppress-errors \
    tests/cifparse_0[1-6]?.inp
