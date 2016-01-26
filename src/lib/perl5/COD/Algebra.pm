#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
#  Contains generic algebraic subroutines.
#**

package COD::Algebra;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    gcd
    gcd2
);

# Find the Greatest Common Divisor (GCD) of two numbers:

sub gcd2
{
    my ($x, $y) = @_;

    die if $x <= 0;
    die if $y <= 0;
    die if $x != int($x);
    die if $y != int($y);

    while( $x != $y ) {
        if( $x > $y ) {
            $x -= $y;
        } else {
            $y -= $x;
        }
    }

    return $x;
}

# Find the Greatest Common Divisor (GCD) of an array of numbers:

sub gcd
{
    my $gcd = pop( @_ );
    for (@_) {
        $gcd = gcd2( $gcd, $_ );
    }

    return $gcd;
}

1;
