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

    return $precision if $precision =~ /\./;

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
