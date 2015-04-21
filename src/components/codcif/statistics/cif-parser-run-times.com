#!/bin/bash

set -ue

OUTPUT_DAT=cif-parser-run-times.dat

ls -ltS ~/struct/cod/hkl/2/* \
| while read -a line
do
    echo ${line[4]} ${line[7]} \
        $(bash -c "time ../cifparse ${line[7]} > /dev/null" 2>&1) \
        | awk '{gsub("0m|s","",$4); print $1, $4, $2}'
done \
| tee ${OUTPUT_DAT}
