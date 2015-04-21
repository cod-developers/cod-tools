#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------

package COD::Precision;

use strict;

require Exporter;
@COD::Precision::ISA = qw(Exporter);
@COD::Precision::EXPORT = qw(unpack_precision unpack_cif_number cmp_cif_numbers);

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

sub unpack_cif_number
{
    my( $number ) = @_;
    my $sigma;
    if( $number =~ s/\((\d+)\)$// ) {
        $sigma = $1;
    }
    my $precision;
    if( defined $sigma ) {
        $precision = unpack_precision( $number, $sigma );
    }
    return wantarray ? ( $number, $precision ) : $number;
}

sub cmp_cif_numbers
{
    my( $x, $y ) = @_;
    my @x = unpack_cif_number( $x );
    my @y = unpack_cif_number( $y );
    return $x[0] <=> $y[0] if !$x[1] && !$y[1];
    if( !$x[1] ) {
        return 0 if $x[0] > $y[0] - $y[1] && $x[0] < $y[0] + $y[1];
        return $x[0] <=> $y[0];
    }
    if( !$y[1] ) {
        return 0 if $y[0] > $x[0] - $x[1] && $y[0] < $x[0] + $x[1];
        return $x[0] <=> $y[0];
    }
    if( $x[0] + $x[1] == $y[0] - $y[1] ||
        $y[0] + $y[1] == $x[0] - $x[1] ) {
        return $x[0] <=> $y[0];
    }
    my @edges = ( [ $x[0] - $x[1],  1 ],
                  [ $x[0] + $x[1], -1 ],
                  [ $y[0] - $y[1],  1 ],
                  [ $y[0] + $y[1], -1 ] );
    my $open_intervals = 0;
    foreach (sort { $a->[0] <=> $b->[0] } @edges) {
        $open_intervals += $_->[1];
        return 0 if $open_intervals > 1;
    }
    return $x[0] <=> $y[0];
}

1;
