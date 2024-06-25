#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/UserMessage.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( sprint_message )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#**
#* Unit test for the COD::UserMessage::sprint_message() subroutine.
#* Tests the way the subroutine escapes various symbols that may
#* interfere with the parsing of the error message.
#**

use strict;
use warnings;

use COD::UserMessage qw( sprint_message );

my @test_symbols = ( ' ', "\n", "\t", '(', ')', '{', '}', '[', ']' );

my $message;
for my $test_symbol ( @test_symbols ) {
    $message = sprint_message( {
        'program'      => "program${test_symbol}",
        'filename'     => "filename${test_symbol}",
        'add_pos'      => "data_block${test_symbol}",
        'err_level'    => 'WARNING',
        'message'      => 'message',
        'line_no'      => 1,
        'column_no'    => 2,
        'line_content' => 'an error line'
    } );
    print "# Contains the '$test_symbol' symbol:\n";
    print $message;
}

END_SCRIPT
