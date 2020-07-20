#!/bin/sh
##
# Tests the way error messages are formed when using COD::UserMessage
# module in command-line perl as well as reading from SDTIN as input file.
##

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE='src/lib/perl5/COD/UserMessage.pm'
#END DEPEND--------------------------------------------------------------------

echo "test error" | \
perl -e 'use COD::UserMessage qw( error );' \
     -e 'print "$ARGV";' \
     -e 'while (<>) {' \
     -e '    error( {' \
     -e '       program  => $0,' \
     -e '       filename => $ARGV,' \
     -e '       message  => $_' \
     -e '    } );' \
     -e '}'
