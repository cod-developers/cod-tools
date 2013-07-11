#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
# Basic symmetry operator algebra (addition, multiplication, etc.)
#**

package SymopAlgebra;

use strict;

require Exporter;
@SymopAlg::ISA = qw(Exporter);
@SymopAlg::EXPORT = qw( );

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

    return wantarray ? @result : \@result;
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

    return wantarray ? @result : \@result;
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

sub vector_negate($)
{
    return [ map {-$_} @{$_[0]} ];
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
    return wantarray ? @ret : \@ret;
}

sub symop_apply($$)
{
    my ( $symop, $vector ) = @_;
    my @result;

    for( my $i = 0; $i < @$vector; $i ++ ) {
        $result[$i] = 0;
        for( my $j = 0; $j < @$vector; $j ++ ) {
            $result[$i] += $symop->[$i][$j] * $vector->[$j];
        }
    }

    if( @$vector == 3 ) {
        for( my $i = 0; $i < @$vector; $i ++ ) {
            $result[$i] += $symop->[$i][3];
        }
    }

    return wantarray ? @result : \@result;
}

1;
