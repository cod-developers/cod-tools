#!/bin/sh

tests/bin/topt \
    -b \
    -b- \
    --flag \
    --int 12345 \
    --float 3.1415926 \
    file1.txt file2.dat
