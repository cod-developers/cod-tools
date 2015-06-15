#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Common subroutines for reading CIF data.
#**

package COD::CIFIO;

use strict;
use warnings;
use COD::CIF2JSON;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    readfile
);

sub readfile
{
    my( $filename, $parser, $options ) = @_;
    $options = {} unless $options;

    my $data;
    my $error_count;
    if(      $parser eq "perl" ) {
        require COD::CIFParser::CIFParser;
        my $parser = new COD::CIFParser::CIFParser;
        $data = $parser->Run( $filename, $options );
        if( defined $parser->YYData->{ERRCOUNT} ) {
            $error_count = $parser->YYData->{ERRCOUNT};
        }
    } elsif( $parser eq "c" ) {
        require COD::CCIFParser::CCIFParser;
        ( $data, $error_count ) =
            COD::CCIFParser::CCIFParser::parse( $filename, $options );
    } elsif( $parser eq "json" ) {
        open( my $inp, $filename );
        my $json = join( "\n", <$inp> );
        close( $inp );
        $data = json2cif( $json );
    } else {
        die "unknown parser '$parser'\n";
    }

    if( defined $error_count && $error_count > 0 ) {
        die $error_count . " error(s) encountered while parsing the file\n";
    }

    return $data;
}

1;
