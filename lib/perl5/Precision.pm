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
    if( defined $2 ) {
        if( defined $4 ) {
            if( defined $3 ) {
                $precision /= 10**(length($3));
            }
            $precision *= 10**($4);
        } else {
            if( defined $3 ) {
                $precision /= 10**(length($3));
            }
        }
    } else {
        $precision *= 10**($4);
    }
    return $precision;    
}
