#!/bin/bash

for RANGE in 0x0080:0x009F 0xD800:0xDFFF 0xFDD0:0xFDEF \
             0x0FFFE:0x0FFFF 0x1FFFE:0x1FFFF 0x2FFFE:0x2FFFF \
             0x3FFFE:0x3FFFF 0x4FFFE:0x4FFFF 0x5FFFE:0x5FFFF \
             0x6FFFE:0x6FFFF 0x7FFFE:0x7FFFF 0x8FFFE:0x8FFFF \
             0x9FFFE:0x9FFFF 0xAFFFE:0xAFFFF 0xBFFFE:0xBFFFF \
             0xCFFFE:0xCFFFF 0xDFFFE:0xDFFFF 0xEFFFE:0xEFFFF \
             0xFFFFE:0xFFFFF 0x10FFFE:0x10FFFF
             
do
    (
        cat <<END
#\#CIF_2.0
data_all_unallowed_Unicode
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
    no warnings;
    print chr( \$i );
}
print "\"\n";
PERLSCRIPT
    ) | ./cifparse 2>&1 | grep 'Unicode codepoint'
done
