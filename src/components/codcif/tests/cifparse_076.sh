#!/bin/sh

set -ue

./cifparse \
    --suppress-errors \
    tests/cifparse_0[1-6]?.inp
