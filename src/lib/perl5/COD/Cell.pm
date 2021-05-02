#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
#  Contains generic subroutines for cell calculations.
#**

package COD::Cell;

use strict;
use warnings;
use COD::Algebra::Vector qw( vector_angle vector_len );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    cell_volume
    vectors2cell
);

sub cell_volume
{
    my @cell = @_;

    for (my $i = 0; $i < scalar(@cell); $i++) {
        if ( !defined $cell[$i] ) {
            warn 'WARNING, at least one of the lattice parameters has an '
               . 'undefined value -- cell volume could not be calculated' . "\n";
            return undef;
        } elsif ( $cell[$i] =~ /^[.?]$/ ) {
            warn 'WARNING, at least one of the lattice parameters has a '
               . "non-numeric value '$1' -- cell volume could not be "
               . 'calculated' . "\n";
            return undef;
        }
        $cell[$i] =~ s/\(.*\)//g;
    }

    my $Pi = 4 * atan2(1,1);

    # Compute unit cell volume:
    my ($a, $b, $c) = @cell[0..2];
    my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);
    my $sg = sin($gamma);
    my $D = $sg**2 - $ca**2 - $cb**2 + 2*$ca*$cb*$cg;

    my $V = $a * $b * $c * sqrt( $D );

    if( wantarray ) {
        # Compute unit cell volume standard deviation, using "error
        # propagation" method:
        my $sa = sin($alpha);
        my $sb = sin($beta);
        my ( $siga, $sigb, $sigc ) = @cell[6..8];
        my ( $sigalpha, $sigbeta, $siggamma ) =
            map {$Pi * $_ / 180} @cell[9..11];
        my $dVda = $sigalpha * $sa * ($ca - $cb * $cg ) / $D;
        my $dVdb = $sigbeta * $sb * ($cb - $ca * $cg ) / $D;
        my $dVdg = $siggamma * $sg * ($cg - $ca * $cb ) / $D;
        my $sigV = $V * sqrt(
            ($siga/$a) ** 2 + ($sigb/$b) ** 2 + ($sigc/$c) ** 2 +
            $dVda ** 2 + $dVdb ** 2 + $dVdg ** 2
            );
        return ( $V, $sigV );
    } else {
        return $V;
    }
}

sub vectors2cell
{
    my( @v ) = @_;
    my @cell = (
        vector_len(  $v[0]),
        vector_len(  $v[1]),
        vector_len(  $v[2]),
        vector_angle($v[1], $v[2]),
        vector_angle($v[0], $v[2]),
        vector_angle($v[0], $v[1])
    );
    return wantarray ? @cell : \@cell;
}

1;
