#! /bin/sh

SCRIPT=$(basename $0 .sh | sed 's/_[0-9][0-9]*.*$//')

./tests/scripts/${SCRIPT} tests/inputs/matrices/random-linear-equation-system3.dat
