#!/bin/sh
##
# Tests the way error messages are formed when using COD::UserMessage
# module in command-line perl as well as reading from SDTIN as input file.
##

echo "test error" | \
perl -e 'use COD::UserMessage; while (<>) { error($0, $ARGV, undef, $_, undef ) }'
