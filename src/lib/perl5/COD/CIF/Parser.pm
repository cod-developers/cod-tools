#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Subroutines that provide a functional interface to COD::CIF::Parser::Yapp
#  and COD::CIF::Parser::Bison CIF parsers.
#**

package COD::CIF::Parser;

use strict;
use warnings;
use COD::CIF::Parser::Yapp;
use COD::CIF::Parser::Bison;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_cif);

sub parse_cif
{
    my ($filename, $options) = @_;

    if ( !defined $options ) {
        $options = { parser => 'c' };
    } elsif( ref $options eq "HASH" ) {
        # this should be a hash reference
    }

    my $parser;

    if ( $options->{parser} eq "c" ) {
        $parser = new COD::CIF::Parser::Bison;
    } elsif ( $options->{parser} eq "perl" ) {
        $parser = new COD::CIF::Parser::Yapp;
    } else {
        # unrecognised hash
    }

    my $data = $parser->Run($filename, $options);

    return ( $data,
             $parser->YYData->{ERRCOUNT},
             $parser->YYData->{ERROR_MESSAGES} );
}
