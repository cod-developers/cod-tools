#!/bin/sh
##
# Tests the way error messages are formed when using COD::UserMessage
# module in command-line perl as well as reading from SDTIN as input file.
##

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/UserMessage.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

echo "test error" | \
perl -M"${IMPORT_MODULE} qw( error )" \
     -e 'print "$ARGV";' \
     -e 'while (<>) {' \
     -e '    error( {' \
     -e '       program  => $0,' \
     -e '       filename => $ARGV,' \
     -e '       message  => $_' \
     -e '    } );' \
     -e '}'
