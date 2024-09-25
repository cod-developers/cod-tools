#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
# Finds the best (in the least squares sense) symmetry operator to move
# mol1 onto mol2, in other words:
#
# operator_2_from_1 = atom_array_overlay( mol1, mol2, ex );
#
# mol2approx[] = symop_vector_mul( operator_2_from_1, mol1[] );
#**

package COD::Overlays::Kabsch;

use strict;
use warnings;
use COD::Algebra::JacobiEigen qw( jacobi_eigenvv );
use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    overlay_atoms
);

sub find_center($)
{
    my $mol = $_[0];
    my $N = scalar( @{$mol} );

    my @sum = (0.0) x 3;
    my $i;
    for( $i = 0; $i < $N; $i++ ) {
        $sum[0] += $mol->[$i]{coordinates_ortho}[0];
        $sum[1] += $mol->[$i]{coordinates_ortho}[1];
        $sum[2] += $mol->[$i]{coordinates_ortho}[2];
    }
    return map {$_/$N} @sum;
}

# uses W. Kabsch's method from:
#
#    Wolfgang Kabsch "A solution for the best rotation to relate two
#    sets of vectors", Acta Cryst. (1976), A32, pp. 922-923
#
# when both molecules m1, m2 are translated so that their centers of
# molecules are in the coordinate origin, the resulting operator
# best_rotation[][] maps (rotates) molecule m1 to molecule m2:
#
#     translated(m2[]) = best_rotation[][] * translated(m1[])
#
# In Kabsch's paper, m1[] corresponds to vector set xn, and m2[]
# corresponds to the vector set yn.

# ( $rotation, $center1, $center2 ) = find_best_fit( $mol1, $mol2 )

sub find_best_fit($$$)
{
    my ( $m1, $m2, $N ) = @_;
    my ( $i, $j, $k, $n );

    my @center1 = find_center( $m1 );
    my @center2 = find_center( $m2 );

    my @s = ( [ 0, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] );
    my @r = ( [ 0, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] );

    for( $n = 0; $n < $N; $n++ ) {
        for( $i = 0; $i < 3; $i++ ) {
            for( $j = 0; $j < 3; $j++ ) {
                my $m1i = $m1->[$n]{coordinates_ortho}[$i] - $center1[$i];
                my $m1j = $m1->[$n]{coordinates_ortho}[$j] - $center1[$j];
                my $m2i = $m2->[$n]{coordinates_ortho}[$i] - $center2[$i];
                $s[$i][$j] += $m1i * $m1j;
                $r[$i][$j] += $m2i * $m1j;
            }
        }
    }

    # RRT = transpose(R) * R
    my @rrt;
    for( $i = 0; $i < 3; $i++ ) {
        for( $j = 0; $j < 3; $j++ ) {
            $rrt[$i][$j] = 0.0;
            for( $k = 0; $k < 3; $k++ ) {
                $rrt[$i][$j] += $r[$k][$i] * $r[$k][$j];
            }
        }
    }

    my( $v, $ev ) = jacobi_eigenvv( @rrt );

    for( $i = 0; $i < 3; $i++ ) {
        if ( $ev->[$i] < 0.0 ) {
            die "ERROR, eigenvalue of the Kabsch's matrix < 0\n"
        };
        $ev->[$i] = sqrt($ev->[$i]);
    }

    my @b;
    for( $i = 0; $i < 3; $i++ ) {
        for( $j = 0; $j < 3; $j++ ) {
            $b[$i][$j] = 0.0;
            for( $k = 0; $k < 3; $k++ ) {
                $b[$i][$j] += $r[$i][$k] * $v->[$k][$j];
            }
            if ( $ev->[$j] <= 0.0 ) {
                die "ERROR, eigenvalue of Kabsch's matrix == 0\n";
            }
            $b[$i][$j] /= $ev->[$j];
        }
    }

    my @best_rotation;
    for( $i = 0; $i < 3; $i++ ) {
        for( $j = 0; $j < 3; $j++ ) {
            $best_rotation[$i][$j] = 0.0;
            for( $k = 0; $k < 3; $k++ ) {
                $best_rotation[$i][$j] += $b[$i][$k] * $v->[$j][$k];
            }
        }
    }

    return ( \@best_rotation, \@center1, \@center2 );
}

sub overlay_atoms($$)
{
    my $molecule1 = shift;
    my $molecule2 = shift;

    my ( $n1, $n2 ) = ( scalar(@$molecule1), scalar(@$molecule2) );
    my $N = $n1 < $n2 ? $n1 : $n2;

    my ($rotation, $center1, $center2 ) =
        find_best_fit( $molecule1, $molecule2, $N );

    my $t = symop_vector_mul( $rotation,
                              [ -$center1->[0],
                                -$center1->[1],
                                -$center1->[2] ] );

    return [
        [ @{$rotation->[0]}[0..2], $t->[0] + $center2->[0] ],
        [ @{$rotation->[1]}[0..2], $t->[1] + $center2->[1] ],
        [ @{$rotation->[2]}[0..2], $t->[2] + $center2->[2] ],
        [ 0, 0, 0, 1 ]
    ];
}

1;
