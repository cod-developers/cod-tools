#!/bin/sh

set -u

./cifparse \
    --quiet \
    --suppress-errors \
    tests/cifparse_0[34]?.inp

echo $?
