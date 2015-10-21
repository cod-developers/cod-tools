#!/bin/sh

set -u

./cifparse \
    --quiet \
    --suppress-errors \
    tests/cifparse_0[1-6]?.inp

echo $?
