#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#*
# Contains generic subroutines to handle parts of the XYZ record,
# such as unit cell and lattice from the comments.
#**

package COD::XYZ;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    unit_cell_from_vectors
    matrix3x3_invert
    cells_are_equal
);

use Math::Trig qw( acos );
use COD::Spacegroups::Symop::Algebra qw( symop_invert );

##
# Given a matrix ref $m ($m = [[$ax, $bx, $cx], [$ay, $by, $cy],
# [$az, $bz, $cz]]), calculate the standard crystallographic unit cell
# parameters: lengths of vectors \vec{a}, \vec{b} and \vec{c}, and
# angle between these three vectors in degrees. Here ($ax,$ay,$az) are
# components of the cell vector \vec{a} in an orthogonal frame, and
# the analogous notation is used for \vec{b} and \vec{c}:
##
sub unit_cell_from_vectors
{
    my ($m) = @_;

    my $Pi = 4 * atan2(1,1);

    my @a = ( $m->[0][0], $m->[1][0], $m->[2][0] );
    my @b = ( $m->[0][1], $m->[1][1], $m->[2][1] );
    my @c = ( $m->[0][2], $m->[1][2], $m->[2][2] );

    my $a = sqrt($a[0]**2 + $a[1]**2 + $a[2]**2);
    my $b = sqrt($b[0]**2 + $b[1]**2 + $b[2]**2);
    my $c = sqrt($c[0]**2 + $c[1]**2 + $c[2]**2);

    my $ab = $a[0]*$b[0] + $a[1]*$b[1] + $a[2]*$b[2];
    my $ac = $a[0]*$c[0] + $a[1]*$c[1] + $a[2]*$c[2];
    my $bc = $c[0]*$b[0] + $c[1]*$b[1] + $c[2]*$b[2];

    my $alpha = acos( $bc/($b*$c) ) * 180 / $Pi;
    my $beta  = acos( $ac/($a*$c) ) * 180 / $Pi;
    my $gamma = acos( $ab/($a*$b) ) * 180 / $Pi;

    return ($a,$b,$c,$alpha,$beta,$gamma);
}

##
# Invert a 3x3 matrix $m ($m = [[$a,$b,$c],[$d,$e,$f],[$g,$h,$i]]).
# Reuse the existing symop_invert() subroutine:
##
sub matrix3x3_invert
{
    my ($m) = @_;

    my $matrix_symop = [
        [ @{$m->[0]}, 0 ],
        [ @{$m->[1]}, 0 ],
        [ @{$m->[2]}, 0 ],
        [ 0, 0, 0,  1 ]
        ];

    my $inverted_symop = symop_invert( $matrix_symop );

    return [
        [ @{$inverted_symop->[0]}[0..2] ],
        [ @{$inverted_symop->[1]}[0..2] ],
        [ @{$inverted_symop->[2]}[0..2] ]
        ];
}

##
# Check whether two unit cells $c1 and $c2, given as Perl array refs,
# are equal. Floating point numbers are deliberately compared using
# numeric equality, so that only cells that have *exactly* the same
# numeric representation are considered equal. Thus, the function will
# err on the side of reporting cells as different when in fact they
# differ only by rounding error. This puts us on the safe side of
# reporting *all* cell mismatches, with possibly of some false alarm
# warnings:
##
sub cells_are_equal
{
    my ($c1,$c2) = @_;

    for my $i (0..$#{$c1}) {
        if( $c1->[$i] != $c2->[$i] ) {
            return 0;
        }
    }
    return 1;
}

1;
