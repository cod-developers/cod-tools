#!/bin/bash

for RANGE in 0x00A0:0xD7FF 0xE000:0xFDCF 0xFDF0:0xFFFD \
                0x10000:0x1FFFD 0x20000:0x2FFFD \
                0x30000:0x3FFFD 0x40000:0x4FFFD \
                0x50000:0x5FFFD 0x60000:0x6FFFD \
                0x70000:0x7FFFD 0x80000:0x8FFFD \
                0x90000:0x9FFFD 0xA0000:0xAFFFD \
                0xB0000:0xBFFFD 0xC0000:0xCFFFD \
                0xD0000:0xDFFFD 0xE0000:0xEFFFD \
                0xF0000:0xFFFFD 0x1000000:0x10FFFD
do
    (
        cat <<END
#\#CIF_2.0
data_all_allowed_Unicode
END

    perl <<PERLSCRIPT
use strict;
use warnings;

binmode STDOUT, "utf8";

my( \$s, \$e ) = split ':', "${RANGE}";
\$s = hex \$s;
\$e = hex \$e;

printf '_start_range_%04X "', \$s;
for my \$i (\$s..\$e) {
    if( (\$i & 0x0F) == 0 ) {
        printf "\"\n_values_from_%04X \"", \$i;
    }
    print chr( \$i );
}
print "\"\n";
PERLSCRIPT
    ) | ./cifparse
done
