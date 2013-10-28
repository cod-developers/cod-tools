#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------

package Precision;

use strict;

require Exporter;
@Precision::ISA = qw(Exporter);
@Precision::EXPORT = qw(unpack_precision);

sub unpack_precision
{
    my( $value, $precision ) = @_;
    # - $1 - part before decimal dot
    # - $2 - decimal dot
    # - $3 - mantissa (part after d-dot)
    # - $4 - exponent
    $value =~ m/
                ([-+]?[0-9]*)?
                (\.)?
                ([0-9]+)?
                (?:e([+-]?[0-9]+))?
            /six;
    my $int_part = (defined $1 ? $1 : 0);
    my $dec_dot = $2;
    my $mantissa = $3;
    my $exponent = (defined $4 ? $4 : 0);
    if( defined $dec_dot && defined $mantissa ) {
        $precision /= 10**(length($mantissa));
    }
    $precision *= 10**($exponent);
    return $precision;    
}
