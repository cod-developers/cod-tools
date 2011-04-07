#!/bin/sh

set -ue

OUTPUT_DAT=cif-parser-run-times.dat

ls -ltS ~/struct/cod/hkl/2/* \
| while read -a line
do
    echo ${line[3]} ${line[6]} \
        $(bash -c "time perl -MCIFParser -e 'new CIFParser->Run(\$ARGV[0])' \
                            ${line[6]}" 2>&1) \
        | awk '{gsub("0m|s","",$4); print $1, $4, $2}'
done \
| tee ${OUTPUT_DAT}
