#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
# Find all eigenvalues and eigenvectors of a symmetric matrix 'a' of order n.
# using the Jacobi method. Implemented as described in 
# "Numerical Recipes: the Art of Scientific Computing, 3rd Edition" pp. 
# 570--576, by Press, H. W and Teukolsky, S. A. and Vetterling, T. W. and 
# Flannery, P. B.
#-----------------------------------------------------------------------

package COD::Algebra::JacobiEigen;

use strict;
use warnings;
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    jacobi_eigenvv
);

our $max_iterations = 100;
# used for float comparison
my $eps = 1;

# jacobi_eigenvv
# expects 2-d array (symmetrical matrix) for which eigenvalues/eigenvectors
#         will be found
# returns ( \@eigenvectors, \@eigenvalues, $sweep_count )

sub jacobi_eigenvv ## ( @ )
{
    my @a = @_;
    my @eigenvalues;
    my @eigenvectors;

    # calculating minimum floating point value
    $eps /= 2 while ($eps/2 + 1) > 1;

    my $n = scalar(@a);
    for( my $i = 0; $i < $n; $i++ ) {
        $eigenvalues[$i] = $a[$i][$i];
        for( my $j = 0; $j < $n; $j++ ) {
            $eigenvectors[$i][$j] = 0.0;
        }
        $eigenvectors[$i][$i] = 1.0;
    }

    for( my $sweep_count = 0; $sweep_count < $max_iterations; $sweep_count++ ) {
        my $sum = &sum_off_diag(@a);
        if( $sum == 0 ) {
            return ( \@eigenvectors, \@eigenvalues, $sweep_count );
        }

        my $thresh = ( $sweep_count < 4 ) ? 0.2 * $sum/($n*$n) : 0.0;

        &jacobi_sweep( \@a, \@eigenvalues, \@eigenvectors, $sweep_count, $thresh );
    }
    die "ERROR, too many iterations in jacobi_eigenvv()\n";
}

sub sum_off_diag( @ )
{
    my @a = @_;

    my $sum = 0.0;
    my $n = scalar(@a);
    for( my $i = 0; $i < $n - 1; $i++ ) {
        for( my $j = $i + 1; $j < $n; $j++ ) {
            $sum += abs($a[$i][$j]);
        }
    }

    return $sum;
}

sub jacobi_transform($$$$$$$)
{
    my( $m, $i, $j, $k, $l, $s, $tau ) = @_;

    my $g = $m->[$i][$j];
    my $h = $m->[$k][$l];
    $m->[$i][$j] = $g - $s * ($h + $g * $tau);
    $m->[$k][$l] = $h + $s * ($g - $h * $tau);
}

sub jacobi_sweep( $$$$$ )
{
    my ( $a, $d, $v, $sweep, $thresh ) = @_;

    my $n = scalar(@{$a});
    my $b = [ map { $_ } @{$d} ];
    my $z = [(0.0)x$n];

    for( my $p = 0; $p < $n-1; $p++ ) {
        for( my $q = $p+1; $q < $n; $q++ ) {
            my $g = 100.0 * abs($a->[$p][$q]);
            if ($sweep > 4 && $g <= $eps*abs($d->[$p]) && 
                              $g <= $eps*abs($d->[$q]) ) {
                $a->[$p][$q] = 0.0;
            } elsif (abs($a->[$p][$q]) > $thresh) {
                my $h = $d->[$q] - $d->[$p];
                my $t;
                if ( $g <= $eps*abs($h)) {
                    $t = ($a->[$p][$q])/$h
                } else {
                    my $theta = 0.5*$h/($a->[$p][$q]);
                    $t = 1.0/(abs($theta)+sqrt(1.0+$theta*$theta));
                    $t = -$t if $theta < 0.0;
                }
                my $c = 1.0/sqrt(1+$t*$t);
                my $s = $t * $c;
                my $tau = $s/(1.0+$c);
                $h = $t*$a->[$p][$q];
                $z->[$p] -= $h;
                $z->[$q] += $h;
                $d->[$p] -= $h;
                $d->[$q] += $h;
                $a->[$p][$q] = 0.0;
                for( my $r = 0; $r < $p; $r++ ) {
                    jacobi_transform( $a,  $r, $p, $r, $q, $s, $tau );
                }
                for( my $r = $p + 1; $r < $q; $r++ ) {
                    jacobi_transform( $a,  $p, $r, $r, $q, $s, $tau );
                }
                for( my $r = $q + 1; $r < $n; $r++ ) {
                    jacobi_transform( $a,  $p, $r, $q, $r, $s, $tau );
                }
                for( my $r = 0; $r < $n; $r++ ) {
                    jacobi_transform( $v,  $r, $p, $r, $q, $s, $tau );
                }
            }
        }
    }

    for (my $i = 0; $i < $n; $i++) {
        $d->[$i] = $b->[$i] + $z->[$i];
    }
}

1;
