#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
# Basic symmetry operator algebra (addition, multiplication, etc.)
#**

package COD::Spacegroups::Symop::Algebra;

use strict;
use warnings;
use POSIX qw( floor );
use COD::Algebra::Vector qw( modulo_1 matrix_vector_mul );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    symop_mul
    symop_vector_mul
    symop_invert
    symop_modulo_1
    snap_to_crystallographic
    symop_translation
    symop_translate
    symop_set_translation
    symop_transpose
    symop_is_unity
    flush_zeros_in_symop
    symop_is_inversion
    symop_matrices_are_equal
    symops_are_equal
    symop_is_translation
    symop_det round_values_in_symop
);


#
# Symop array contains the following values:
# my $symop = [
#     [ r11 r12 r13 t1 ]
#     [ r21 r22 r23 t2 ]
#     [ r31 r32 r33 t3 ]
#     [   0   0   0  1 ]
# ]
#

sub symop_mul($$)
{
    my ( $s1, $s2 ) = @_;

    my @result;
    for( my $i = 0; $i < @$s1; $i++ ) {
        for( my $j = 0; $j < @$s2; $j++ ) {
            $result[$i][$j] = 0;
            for( my $k = 0; $k < @$s2; $k++ ) {
                $result[$i][$j] += $s1->[$i][$k] * $s2->[$k][$j];
            }
        }
    }

    return \@result;
}

sub symop_modulo_1($)
{
    my ( $symop ) = @_;

    my @result = (
        [ @{$symop->[0]} ],
        [ @{$symop->[1]} ],
        [ @{$symop->[2]} ],
        [ @{$symop->[3]} ],
    );

    $result[0][3] = modulo_1( $symop->[0][3] );
    $result[1][3] = modulo_1( $symop->[1][3] );
    $result[2][3] = modulo_1( $symop->[2][3] );
    $result[3][3] = 1;

    return \@result;
}

sub snap_number_to_crystallographic
    # Round symop matrix values to the nearest "crystallographic"
    # value.
{
    my ($value, $eps) = @_;

    $eps = 1E-6 unless defined $eps;

    if( abs($value) < $eps ) {
        return 0.0;
    }
    if( abs($value - 1) < $eps ) {
        return 1.0;
    }
    if( abs($value - 1/2) < $eps ) {
        return 1/2;
    }
    if( abs($value - 1/3) < $eps ) {
        return 1/3;
    }
    if( abs($value - 2/3) < $eps ) {
        return 2/3;
    }
    if( abs($value - 1/4) < $eps ) {
        return 1/4;
    }
    if( abs($value - 3/4) < $eps ) {
        return 3/4;
    }
    if( abs($value - 1/6) < $eps ) {
        return 1/6;
    }
    if( abs($value - 5/6) < $eps ) {
        return 5/6;
    }
    if( abs($value - 1.0) < $eps ) {
        return 1;
    }

    return $value;
}

sub snap_to_crystallographic
{
    my ($vector) = @_;

    for(@$vector) {
        if( ref $_ ) {
            snap_to_crystallographic( $_ );
        } else {
            $_ = snap_number_to_crystallographic( $_ );
        }
    }
    return $vector;
}

sub symop_translate($$)
{
    my ( $symop, $vector ) = @_;

    my @result = (
        [ @{$symop->[0]} ],
        [ @{$symop->[1]} ],
        [ @{$symop->[2]} ],
        [ @{$symop->[3]} ],
        );

    $result[0][3] += $vector->[0];
    $result[1][3] += $vector->[1];
    $result[2][3] += $vector->[2];

    return \@result;
}

sub symop_set_translation($$)
{
    my ( $symop, $vector ) = @_;

    my @result = (
        [ @{$symop->[0]} ],
        [ @{$symop->[1]} ],
        [ @{$symop->[2]} ],
        [ @{$symop->[3]} ],
        );

    $result[0][3] = $vector->[0];
    $result[1][3] = $vector->[1];
    $result[2][3] = $vector->[2];
    $result[3][3] = 1;

    return \@result;
}

sub symop_adjunct($$$)
{
    my ( $s, $row, $col ) = @_;

    my @matrix = ();
    my ( $i, $j, $mi, $mj );
    my $coef;

    die unless( $row >= 0 && $row < 4 );
    die unless( $col >= 0 && $col < 4 );

    $mi = $mj = 0;
    for( $i = 0; $i < 4; $i ++ ) {
        next if( $i == $row );
        $mj = 0;
        for( $j = 0; $j < 4; $j ++ ) {
            next if( $j == $col );
            $matrix[$mi][$mj] = $s->[$i][$j];
            $mj ++;
        }
        $mi ++;
    }
    die unless( $mi == 3 );
    die unless( $mj == 3 );
    $coef = (($row + $col) % 2 == 0) ? +1.0 : -1.0;
    return $coef * symop_det( \@matrix );
}

sub symop_det( $ )
{
    my $s = $_[0];
    return
        + $s->[0][0] * $s->[1][1] * $s->[2][2]
        + $s->[1][0] * $s->[2][1] * $s->[0][2]
        + $s->[0][1] * $s->[1][2] * $s->[2][0]

        - $s->[0][2] * $s->[1][1] * $s->[2][0]
        - $s->[0][0] * $s->[1][2] * $s->[2][1]
        - $s->[0][1] * $s->[1][0] * $s->[2][2];
}

sub symop_invert( $ )
{
    my $s = $_[0];
    my @ret;
    my $det = symop_det( $s );
    my ( $i, $j );

    for( my $i = 0; $i < 4; $i++ ) {
        for( my $j = 0; $j < 4; $j++ ) {
            $ret[$i][$j] = symop_adjunct($s,$j,$i) / $det;
        }
    }
    return \@ret;
}

sub symop_is_inversion
{
    my ($symop) = @_;

    for( my $i = 0; $i < 3; $i++ ) {
        for( my $j = 0; $j < 3; $j++ ) {
            if( $i == $j && $symop->[$i][$j] != -1.0 ||
                $i != $j && $symop->[$i][$j] != 0.0 ) {
                return 0;
            }
        }
    }
    return 1;
}

sub symop_is_translation
{
    my ($symop) = @_;

    for( my $i = 0; $i < 3; $i++ ) {
        for( my $j = 0; $j < 3; $j++ ) {
            if( $i == $j && $symop->[$i][$j] != 1.0 ||
                $i != $j && $symop->[$i][$j] != 0.0 ) {
                return 0;
            }
        }
    }
    return 1;
}

sub matrices_are_equal
    # Compare two matrices of they are equal. The '$n' parameter
    # specifies the size of the matrix to be compared; the actual $s1
    # and $s2 matrices may be larger than that; in this case only
    # upper left square sub-matrices of size $n will be compared.
    #
    # N.B. Floats, if present, will be compared to equality; special
    # care must be taken to eliminate rounding errors
{
    my ($s1, $s2, $n) = @_;

    for( my $i = 0; $i < $n; $i++ ) {
        for( my $j = 0; $j < $n; $j++ ) {
            if( $s1->[$i][$j] != $s2->[$i][$j] ) {
                return 0;
            }
        }
    }
    return 1;
}


sub symop_matrices_are_equal
    # Compare only the rotation part of the symmetry operator.
{
    my ($s1, $s2) = @_;
    return matrices_are_equal( $s1, $s2, 3 );
}

sub symops_are_equal
    # Compare full symmetry operators (4x4 matrices), which includes
    # both rotation and translation parts.
{
    my ($s1, $s2) = @_;
    return matrices_are_equal( $s1, $s2, 4 );
}

sub symop_translation($)
{
    my ( $symop ) = @_;

    my @translation = (
        $symop->[0][3],
        $symop->[1][3],
        $symop->[2][3]
    );

    return \@translation;
}

sub flush_zeros_in_symop($@)
{
    my ( $symop, $epsilon ) = @_;

    $epsilon = 1E-6 unless defined $epsilon;

    for my $row (@$symop) {
        for my $value (@$row) {
            if( abs($value) < $epsilon ) {
                $value = 0.0;
            }
        }
    }

    return $symop;
}

sub round_values_in_symop($@)
{
    my ( $symop, $eps ) = @_;

    $eps = 1E-6 unless defined $eps;

    for my $row (@$symop) {
        for my $value (@$row) {
            $value = POSIX::floor($value/$eps + 0.5)*$eps;
        }
    }

    return $symop;
}

sub symop_transpose($)
{
    my( $symop ) = @_;

    my $result = [];
    for my $i (0..$#{$symop}) {
        for my $j (0..$#{$symop->[$i]}) {
            push( @$result, [] ) if @$result <= $j;
            $result->[$j][$i] = $symop->[$i][$j];
        }
    }
    return $result;
}

sub symop_is_unity($)
{
    my($symop) = @_;
    my $eps = 1e-10;

    for(my $i = 0; $i < @{$symop}; $i++)
    {
        for(my $j = 0; $j < @{$symop}; $j++)
        {
            if($i == $j)
            {
                if(abs(${$symop}[$i][$j] - 1) > $eps) {
                    return 0;
                }
            }
            else
            {
                if(abs(${$symop}[$i][$j] - 0) > $eps) {
                    return 0;
                }
            }
        }
    }
    return 1;
}

sub symop_vector_mul($$)
{
    my($symop, $vector) = @_;

    my @new_coordinates = matrix_vector_mul($symop, $vector);

    if( @$vector == 3 && @$symop == 4 ) {
        $new_coordinates[0] += $symop->[0][3];
        $new_coordinates[1] += $symop->[1][3];
        $new_coordinates[2] += $symop->[2][3];
    }

    return \@new_coordinates;
}

1;
