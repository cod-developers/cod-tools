#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
# Find all eigenvalues and eigenvectors of a symmetric matrix a of order n.
#-----------------------------------------------------------------------

package COD::Algebra::JacobiEigenSimple;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    jacobi_eigenvv
);

$COD::Algebra::JacobiEigenSimple::max_iterations = 100;
# used for float comparison
$COD::Algebra::JacobiEigenSimple::delta  = 1e-100;

# jacobi_eigenvv
# expects 2-d array (symmetrical matrix) for which eigenvalues/eigenvectors
#         will be found
# returns ( \@eigenvectors, \@eigrnvalues, $sweep_count )

sub jacobi_eigenvv ## ( @ )
{
    my @a = @_;
    my ( $i, $j, $sweep_count );
    my @eigenvalues;
    my @eigenvectors;

    my $n = scalar(@a);
    for( $i = 0; $i < $n; $i++ ) {
        $eigenvalues[$i] = $a[$i][$i];
        for( $j = 0; $j < $n; $j++ ) {
            $eigenvectors[$i][$j] = 0.0;
        }
        $eigenvectors[$i][$i] = 1.0;
    }

    for( $sweep_count = 0; $sweep_count < $COD::Algebra::JacobiEigenSimple::max_iterations;
         $sweep_count++ ) {
        if( &sum_off_diag(@a) < $COD::Algebra::JacobiEigenSimple::delta ) {
            return ( \@eigenvectors, \@eigenvalues, $sweep_count );
        }
        &jacobi_sweep( \@a, \@eigenvalues, \@eigenvectors );
    }
    die( "Too many iterations in jacobi_eigenvv()" );
}

sub sum_off_diag( @ )
{
    my @a = @_;
    my ( $i, $j );
    my $sum = 0.0;

    my $n = scalar(@a);
    for( $i = 0; $i < $n - 1; $i++ ) {
        for( $j = $i + 1; $j < $n; $j++ ) {
            $sum += abs($a[$i][$j]);
        }
    }

    return $sum;
}

sub jacobi_transform($$$$$$$)
{
    my( $m, $i, $j, $k, $l, $c, $s ) = @_;

    my $g = $m->[$i][$j]; my $h = $m->[$k][$l];
    $m->[$i][$j] =  $g * $c + $h * $s;
    $m->[$k][$l] =  $h * $c - $g * $s;
}

sub jacobi_sweep( $$$ )
{
    my ( $a, $d, $v ) = @_;
    my ( $s, $c, $R, $g, $h );
    my ( $p, $q, $r );

    my $n = scalar(@{$a});
    for( $p = 0; $p < $n-1; $p++ ) {
        for( $q = $p+1; $q < $n; $q++ ) {
            $h = $d->[$p] - $d->[$q];
            $R = sqrt($h*$h + 4*$a->[$p][$q]*$a->[$p][$q]);
            if( $d->[$p] > $d->[$q] ) {
                $c = sqrt(0.5 + $h/(2*$R));
                $s = $a->[$p][$q]/($R*$c);
            } else {
                $s = sqrt(0.5 - $h/(2*$R));
                $c = $a->[$p][$q]/($R*$s);
            }
            $h = $d->[$p] + $d->[$q];
            $d->[$p] = 0.5*($h+$R);
            $d->[$q] = 0.5*($h-$R);
            $a->[$p][$q] = 0.0;
            for( $r = 0; $r < $p; $r++ ) {
                jacobi_transform( $a,  $r, $p,  $r, $q, $c, $s );
            }
            for( $r = $p + 1; $r < $q; $r++ ) {
                jacobi_transform( $a,  $p, $r,  $r, $q, $c, $s );
            }
            for( $r = $q + 1; $r < $n; $r++ ) {
                jacobi_transform( $a,  $p, $r,  $q, $r, $c, $s );
            }
            for( $r = 0; $r < $n; $r++ ) {
                jacobi_transform( $v,  $r, $p,  $r, $q, $c, $s );
            }
        }
    }
}

1;
