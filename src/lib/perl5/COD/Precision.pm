#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------

package COD::Precision;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cmp_cif_numbers
    eqsig
    unpack_precision
    unpack_cif_number
);

sub unpack_precision
{
    my( $value, $precision ) = @_;

    return $precision if $precision =~ /[.]/;

    $value =~ m/
                [-+]?                # number sign
                (?:[0-9]+)?          # part before the decimal dot
                ([.])?               # $1 - decimal dot
                ([0-9]+)?            # $2 - mantissa (part after d-dot)
                (?:e([+-]?[0-9]+))?  # $3 - exponent
            /six;
    my $dec_dot  = $1;
    my $mantissa = $2;
    my $exponent = $3;

    if( defined $dec_dot && defined $mantissa ) {
        $precision /= 10**(length($mantissa));
    }

    if ( defined $exponent ) {
        $precision *= 10**($exponent);
    }

    return $precision;
}

sub unpack_cif_number
{
    my( $number ) = @_;
    my $sigma;
    if( $number =~ s/\(([0-9\.]+)\)$// ) {
        $sigma = $1;
    }
    my $precision;
    if( defined $sigma ) {
        $precision = unpack_precision( $number, $sigma );
    }
    return wantarray ? ( $number, $precision ) : $number;
}

sub eqsig
{
    my ( $x, $sigx, $y, $sigy ) = @_;

    $sigx = 0.0 unless defined $sigx;
    $sigy = 0.0 unless defined $sigy;

    return ($x - $y)**2 <= 9 * ($sigx**2 + $sigy**2);
}

sub cmp_cif_numbers
{
    my( $x, $y ) = @_;
    my( $xval, $sigx ) = unpack_cif_number( $x );
    my( $yval, $sigy ) = unpack_cif_number( $y );
    return 0 if eqsig( $xval, $sigx, $yval, $sigy );
    return $xval <=> $yval;
}

1;
