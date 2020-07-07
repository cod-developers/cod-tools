#-----------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#
# Calculates the smallest RMSD of superposition for two sets of points.
#
# Used algorithm is described in:
#   Theobald, D. L. "Rapid calculation of RMSDs using a quaternion-based
#   characteristic polynomial ", Acta Crystallographica Section A, 2005, A61,
#   478-480,
#   doi: 10.1107/S0108767305015266
#*
package COD::Overlays::Theobald;

use strict;
use warnings;

# Epsilon that is used to compare floats
our $eps = 1E-8;
# Minimum threshold of the derivative
our $tolerance = 1E-200;
# Maximum number of iterations
our $maxIteration = 100;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    overlay_atoms
    overlay_points
);

sub overlay_atoms($$);
sub overlay_points($$$);

sub overlay_atoms($$)
{
    my ( $atoms1, $atoms2 ) = @_;

    my $set1 = [ map {$_->{coordinates_ortho}} @$atoms1 ];
    my $set2 = [ map {$_->{coordinates_ortho}} @$atoms2 ];

    return overlay_points( $set1, $set2, {} );
}

sub overlay_points($$$)
{
    my ( $set1, $set2, $centers ) = @_;

    if ( @{$set1} != @{$set2} ) {
        die "superpositioned sets do not contain the same number of points";
    };

    my $center1 = find_center($set1) if !defined $centers->{center1};
    my $center2 = find_center($set2) if !defined $centers->{center2};

    my $cent_set1 = move_origin($set1, $center1);
    my $cent_set2 = move_origin($set2, $center2);

    my $qcp = get_polynomial($cent_set1, $cent_set2);
    my $lmb = (inner_product($cent_set1) + inner_product($cent_set2)) * 0.5;
    my $rmsd = Newton_Raphson($qcp, $lmb);

    $rmsd = sqrt ( abs( 2 * ($lmb - $rmsd) ) / scalar(@$cent_set1) );

    return $rmsd;
}

# structure B is superimposed on structure A
sub get_polynomial($$) {

    my ($A, $B) = @_;

    my $A_x = get_column($A, 1);
    my $A_y = get_column($A, 2);
    my $A_z = get_column($A, 3);
    my $B_x = get_column($B, 1);
    my $B_y = get_column($B, 2);
    my $B_z = get_column($B, 3);

    my $S_xx = mult_sum($B_x, $A_x);
    my $S_xy = mult_sum($B_x, $A_y);
    my $S_xz = mult_sum($B_x, $A_z);
    my $S_yx = mult_sum($B_y, $A_x);
    my $S_yy = mult_sum($B_y, $A_y);
    my $S_yz = mult_sum($B_y, $A_z);
    my $S_zx = mult_sum($B_z, $A_x);
    my $S_zy = mult_sum($B_z, $A_y);
    my $S_zz = mult_sum($B_z, $A_z);

    my ( $S_xx2, $S_xy2, $S_xz2 ) = ( $S_xx**2, $S_xy**2, $S_xz**2 );
    my ( $S_yx2, $S_yy2, $S_yz2 ) = ( $S_yx**2, $S_yy**2, $S_yz**2 );
    my ( $S_zx2, $S_zy2, $S_zz2 ) = ( $S_zx**2, $S_zy**2, $S_zz**2 );

    # p stands for +, m stands for -
    my $S_xz_p_zx = $S_xz + $S_zx;
    my $S_xz_m_zx = $S_xz - $S_zx;
    my $S_yz_p_zy = $S_yz + $S_zy;
    my $S_yz_m_zy = $S_yz - $S_zy;
    my $S_xy_p_yx = $S_xy + $S_yx;
    my $S_xy_m_yx = $S_xy - $S_yx;
    my $S_xx_p_yy_p_zz = $S_xx + $S_yy + $S_zz;
    my $S_xx_p_yy_m_zz = $S_xx + $S_yy - $S_zz;
    my $S_xx_m_yy_p_zz = $S_xx - $S_yy + $S_zz;
    my $S_xx_m_yy_m_zz = $S_xx - $S_yy - $S_zz;
    my $S_xx2_yy2_zz2_yz2_zy2 = -$S_xx2 + $S_yy2 + $S_zz2 + $S_yz2 + $S_zy2;
    my $S_yyzz_m_yzzy = 2 * ($S_yy*$S_zz - $S_yz*$S_zy);

    my $D = ( $S_xy2 + $S_xz2 - $S_yx2 - $S_zx2 )**2;
    my $E = ( $S_xx2_yy2_zz2_yz2_zy2 - $S_yyzz_m_yzzy ) *
            ( $S_xx2_yy2_zz2_yz2_zy2 + $S_yyzz_m_yzzy );

    my $F = ( -($S_xz_p_zx*$S_yz_m_zy) + $S_xy_m_yx * $S_xx_m_yy_m_zz ) *
            ( -($S_xz_m_zx*$S_yz_p_zy) + $S_xy_m_yx * $S_xx_m_yy_p_zz );

    my $G = ( -($S_xz_p_zx*$S_yz_p_zy) - $S_xy_p_yx * $S_xx_p_yy_m_zz ) *
            ( -($S_xz_m_zx*$S_yz_m_zy) - $S_xy_p_yx * $S_xx_p_yy_p_zz );

    my $H = (   $S_xy_p_yx*$S_yz_p_zy  + $S_xz_p_zx * $S_xx_m_yy_p_zz ) * 
            ( -($S_xy_m_yx*$S_yz_m_zy) + $S_xz_p_zx * $S_xx_p_yy_p_zz );

    my $I = (   $S_xy_p_yx*$S_yz_m_zy  + $S_xz_m_zx * $S_xx_m_yy_m_zz ) *
            ( -($S_xy_m_yx*$S_yz_p_zy) + $S_xz_m_zx * $S_xx_p_yy_m_zz );

    my $C_0 = $D + $E + $F + $G + $H + $I;
    my $C_1 = 8*($S_xx*$S_yz*$S_zy + $S_yy*$S_zx*$S_xz + $S_zz*$S_xy*$S_yx) - 
              8*($S_xx*$S_yy*$S_zz + $S_yz*$S_zx*$S_xy + $S_zy*$S_yx*$S_xz);
    my $C_2 = -2*( $S_xx2 + $S_xy2 + $S_xz2 + 
                   $S_yx2 + $S_yy2 + $S_yz2 +
                   $S_zx2 + $S_zy2 + $S_zz2);

    return [$C_0, $C_1, $C_2];
}

##
# Calculates the maximum root of Quaternion Characteristic Polynomial (QCP) 
# using Newton-Raphson algorithm.
# @param c
#   Reference to an array of QCP coefficients.
# @param $x
#   Initial guess of the root value.
# @return $x
#   The highest root of QCP.
##
sub Newton_Raphson
{
    my ($c, $x) = @_;

    # In case our initial guess is the right solution
    return $x if ( ($x**4 + $c->[2]*$x**2 + $c->[1]*$x + $c->[0]) == 0);

    my $i;
    for ($i = 0; $i < $maxIteration; $i++) {
        my $x_old = $x;
        # Breaking QCP and its derivative into parts to minimize calculations
        my $x2 = $x**2;
        my $b = ($x2 + $c->[2])*$x;
        my $a = $b + $c->[1];
        my $func = $a*$x + $c->[0];
        my $deriv = (2.0*$x2*$x + $b + $a);
        if ( $deriv < $tolerance ) {
            die "derivative function value has reached the tolerance limit " .
                "'$tolerance' in Newton-Raphson QCP before converging.";
        }

        $x -= $func/$deriv;

        last if (abs(($x - $x_old)) < abs($eps*$x));
    }

    if ($i == $maxIteration) {
        die "Newton-Raphson QCP did not converge in $maxIteration iterations.";
    }

    return $x;
}

sub inner_product
{
    my ($matrix) = @_;

    my $product = 0;
    foreach my $row (@$matrix) {
        $product += $row->[$_]**2 for 0..2;
    }

    return $product;
}

##
# Returns a column from a matrix represented in a row-major layout.
##
sub get_column
{
    my ( $matrix, $col_num ) = @_;
    return [map {$_->[$col_num-1]} @$matrix];
}

##
# Multiplies two equal sized arrays element-wise and returns the sum of their 
# products.
##
sub mult_sum
{
    my ( $arr1, $arr2 ) = @_;

    my $sum = 0;
    for (my $i = 0; $i < @$arr1; $i++) {
        $sum = $sum + $arr1->[$i] * $arr2->[$i];
    }

    return $sum;
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
