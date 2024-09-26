#-----------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
# Constructs the best symmetry operator to superposition two sets of points.
# Distance between sets of points is measured in rmsd. The algorithm allows
# to easily calculate the rmsd value from the eigenvalue without the need to
# apply the symmetry operator. In case of a negative eigenvalue, undef is
# returned instead of rmsd.
#
# Used algorithm is decribed in:
#   Kearsley, S. K. "On the orthogonal transformation used for structural
#   comparisons", Acta Crystallographica Section A, 1989, 45, 208-210,
#   doi: 10.1107/S0108767388010128
#
# Usage:
#   # Find operator matrix to best fit set1 onto set2
#   (symop_2_from_1, rmsd) = overlay_atoms( set1[][], set2[][] );
#   set2approx[] = symop_vector_mul( symop_2_from_1, set1[][] );
#**

package COD::Overlays::Kearsley;

use strict;
use warnings;
use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul );
use COD::Algebra::JacobiEigen qw( jacobi_eigenvv );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    overlay_atoms
    overlay_points
    get_rotation_matrix
);

sub overlay_atoms($$);
sub overlay_points($$$);
sub get_rotation_matrix($$);

sub overlay_atoms($$);
sub overlay_points($$$);

##
# Overlays two sets of atoms. A wrapper subroutine for overlay_points.
#
# @param $set1, $set2
#       Sets of points to be superimposed. $set1 is superimposed on $set2.
#
# @return $symop
#       Rotation (r) and translation (t) matrix following the affine form:
#       [
#          [ r11 r12 r13 t1 ]
#          [ r21 r22 r23 t2 ]
#          [ r31 r32 r33 t3 ]
#          [   0   0   0  1 ]
#       ]
# @return $rmsd
#       Minimal root mean square deviation between the two sets of points.
##
sub overlay_atoms($$)
{
    my ( $set1, $set2 ) = @_;

    $set1 = [ map {$_->{coordinates_ortho}} @$set1 ];
    $set2 = [ map {$_->{coordinates_ortho}} @$set2 ];

    return overlay_points( $set1, $set2, {} );
}

##
# Constructs best operator matrix to superimpose two sets of points.
# set1 is superimposed onto set2. RMSD value between the two sets is also
# calculated as a step of the algorithm.
#
# @param $set1, $set2
#       Sets of points to be superimposed. $set1 is superimposed on $set2.
# @param $centers
#       Optional parameter. Hash reference, containing origin points for
#       superimposed sets. If values are not provided, sets are shifted
#       in a way for their origins to coincide with their centroids.
#
# @return $symop
#       Rotation (r) and translation (t) matrix following the affine form:
#       [
#          [ r11 r12 r13 t1 ]
#          [ r21 r22 r23 t2 ]
#          [ r31 r32 r33 t3 ]
#          [   0   0   0  1 ]
#       ]
# @return $rmsd
#       Minimal root mean square deviation between the two sets of points.
##
sub overlay_points($$$)
{
    my ( $set1, $set2, $centers ) = @_;

    if ( @{$set1} != @{$set2} ) {
        die 'ERROR, superpositioned sets do not contain the same '
          . 'number of points' . "\n";
    };

    my $center1 = find_center($set1) if !defined $centers->{center1};
    my $center2 = find_center($set2) if !defined $centers->{center2};

    my $cent_set1 = move_origin($set1, $center1);
    my $cent_set2 = move_origin($set2, $center2);

    my ($R, $rmsd) = get_rotation_matrix($cent_set1, $cent_set2);

    my $t = symop_vector_mul( $R,
                              [ -$center1->[0],
                                -$center1->[1],
                                -$center1->[2] ] );

    my $symop = [
                  [ @{$R->[0]}[0..2], $t->[0] + $center2->[0] ],
                  [ @{$R->[1]}[0..2], $t->[1] + $center2->[1] ],
                  [ @{$R->[2]}[0..2], $t->[2] + $center2->[2] ],
                  [ 0, 0, 0, 1 ]
                ];

    return ( $symop, $rmsd );
}

sub get_rotation_matrix($$)
{
    my ( $set1, $set2 ) = @_;

    my $N = scalar(@{$set1});

    if ( @{$set1} != @{$set2} ) {
        die 'ERROR, superpositioned sets do not contain the same number of '
          . 'points' . "\n";
    };

    $set1 = matrix_to_list($set1);
    $set2 = matrix_to_list($set2);

    if ( @{$set1} != @{$set2} ) {
        die 'ERROR, not all points of the superpositioned sets are '
          . 'of the same dimmensions' . "\n";
    };

    my $set_p = [ map { $set2->[$_] + $set1->[$_] } 0..$#$set1 ];
    my $set_m = [ map { $set2->[$_] - $set1->[$_] } 0..$#$set1 ];

    # Extract x, y, z coordinate columns into arrays
    my $x_p = get_column($set_p, 3, 1);
    my $y_p = get_column($set_p, 3, 2);
    my $z_p = get_column($set_p, 3, 3);

    my $x_m = get_column($set_m, 3, 1);
    my $y_m = get_column($set_m, 3, 2);
    my $z_m = get_column($set_m, 3, 3);

    # Construct quaternion matrix for eigenvalue decomposition.
    my $a11 = mult_sum($x_m,$x_m) + mult_sum($y_m,$y_m) + mult_sum($z_m,$z_m);
    my $a12 = mult_sum($y_p,$z_m) - mult_sum($y_m,$z_p);
    my $a13 = mult_sum($x_m,$z_p) - mult_sum($x_p,$z_m);
    my $a14 = mult_sum($x_p,$y_m) - mult_sum($x_m,$y_p);
    my $a22 = mult_sum($y_p,$y_p) + mult_sum($z_p,$z_p) + mult_sum($x_m,$x_m);
    my $a23 = mult_sum($x_m,$y_m) - mult_sum($x_p,$y_p);
    my $a24 = mult_sum($x_m,$z_m) - mult_sum($x_p,$z_p);
    my $a33 = mult_sum($x_p,$x_p) + mult_sum($z_p,$z_p) + mult_sum($y_m,$y_m);
    my $a34 = mult_sum($y_m,$z_m) - mult_sum($y_p,$z_p);
    my $a44 = mult_sum($x_p,$x_p) + mult_sum($y_p,$y_p) + mult_sum($z_m,$z_m);

    # Decompose matrix and choose the eigenvector with the smallest eigenvalue
    my @qmatrix = ( [$a11, $a12, $a13, $a14],
                    [$a12, $a22, $a23, $a24],
                    [$a13, $a23, $a33, $a34],
                    [$a14, $a24, $a34, $a44] );

    my( $eigenvectors, $eigenvalues ) = jacobi_eigenvv( @qmatrix );

    my $min;
    my $found_negative_eigenvalues = 0;
    for (my $i = 0; $i < @$eigenvalues; $i++) {
        if (@$eigenvalues[$i] > 0) {
            $found_negative_eigenvalues = 1;
            next;
        }

        if (!defined $min || @$eigenvalues[$i] <= @$eigenvalues[$min]) {
            $min = $i;
        }
    }

    if ( !defined $min ) {
        die 'ERROR, no positive eigenvalues were produced' . "\n";
    } elsif ( $found_negative_eigenvalues ) {
        warn 'WARNING, negative eigenvalues were produced, taking the smallest '
           . 'positive eigenvalue' . "\n";
    }

    my $eigenvector = @$eigenvectors[$min];
    my $eigenvalue  = @$eigenvalues[$min];

    my $rmsd = sqrt(abs($eigenvalue)/$N);

    my $R = construct_rotation_matrix($eigenvector);

    return ($R, $rmsd);
}

##
# Constructs best rotation matrix from quaternion elements.
##
sub construct_rotation_matrix ($)
{
    my $q = $_[0];

    my ($q1, $q2, $q3, $q4) = @$q;

    my $a11 = $q1*$q1 + $q2*$q2 - $q3*$q3 - $q4*$q4;
    my $a22 = $q1*$q1 + $q3*$q3 - $q2*$q2 - $q4*$q4;
    my $a33 = $q1*$q1 + $q4*$q4 - $q2*$q2 - $q3*$q3;
    my $a12 = 2.0*($q2*$q3 + $q1*$q4);
    my $a21 = 2.0*($q2*$q3 - $q1*$q4);
    my $a13 = 2.0*($q2*$q4 - $q1*$q3);
    my $a31 = 2.0*($q2*$q4 + $q1*$q3);
    my $a23 = 2.0*($q3*$q4 + $q1*$q2);
    my $a32 = 2.0*($q3*$q4 - $q1*$q2);

    my $R = [ [ $a11, $a12, $a13 ],
              [ $a21, $a22, $a23 ],
              [ $a31, $a32, $a33 ] ];

    return $R;
}

##
# Multiplies two equal sized arrays element-wise and returns the sum of their
# products.
##
sub mult_sum
{
    my ( $arr1, $arr2 ) = @_;

    my $sum = 0;
    $sum += $_ for map {$arr1->[$_] * $arr2->[$_]} 0..$#$arr1;

    return $sum;
}

##
# Returns a column from a matrix represented in a row-major layout.
##
sub get_column
{
    my ( $matrix, $col_count, $col_num ) = @_;

    my @column;
    for ( my $i = 0; $i < @$matrix; $i++ ) {
        push @column, $matrix->[$i] if ( ( $i % $col_count ) + 1 ) == $col_num;
    }

    return \@column;
}

##
# Converts matrix from multidimensional array form to a row-major layout list.
##
sub matrix_to_list
{
    my ($matrix) = @_;

    my @list;
    push @list, @$_ for @$matrix;

    return \@list;
}

sub find_center($)
{
    my $set = $_[0];

    my @sum = (0.0) x 3;
    foreach my $point (@$set) {
        $sum[$_] += $point->[$_] for 0..2;
    }

    return [ map {$_/@$set} @sum ];
}

sub move_origin($$)
{
    my ($set, $center) = @_;

    my @cent_set;
    foreach my $point (@$set) {
        my @cent_point;
        push @cent_point, $point->[$_] - $center->[$_] for 0..$#$center;
        push @cent_set, \@cent_point;
    }

    return \@cent_set;
}

1;
