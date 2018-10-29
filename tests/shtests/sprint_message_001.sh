#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/UserMessage.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
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

use COD::UserMessage qw( sprint_message parse_message );

my @test_symbols = ( ' ', "\n", "\t", '(', ')', '{', '}', '[', ']' );

my $message;
for my $test_symbol ( @test_symbols ) {
    $message = sprint_message(
        "program${test_symbol}",
        "filename${test_symbol}",
        "data_block${test_symbol}",
        'WARNING',
        'message',
        undef,
        1,
        2,
        'an error line'
    );
    print "# Contains the '$test_symbol' symbol:\n";
    print $message;
}

END_SCRIPT
