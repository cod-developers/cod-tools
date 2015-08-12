#!/bin/sh

set -u

./cifparse \
    --fix \
    --quiet \
    --suppress-errors \
    tests/cifparse_0[34]?.inp

echo $?
