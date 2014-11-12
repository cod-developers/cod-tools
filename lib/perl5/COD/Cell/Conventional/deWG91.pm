#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Perl package implementing the de Wollf & Gruber 1991 algorithm for
#  conventional cell (character) determination (de Wolff, P. M. &
#  Gruber, B. Niggli lattice characters: definition and graphical
#  representation Acta Crystallographica Section A, 1991, 47, 29-36,
#  http://dx.doi.org/10.1107/S0108767390009485)
#**

package deWG91;

use strict;
use warnings;
require Exporter;
@deWG91::ISA = qw(Exporter);
@deWG91::EXPORT_OK = qw(  );

my $Pi = 4 * atan2(1,1);

$KG76::debug = 1;

sub conventional_cell
{
    my @cell = @_;

    my $eps = @cell > 6 ? pop(@cell) : 1E-2;

    my ($a, $b, $c, $alpha, $beta, $gamma ) =
        (@cell[0..2], map { $Pi * $_ / 180 }  @cell[3..5]);

    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);

    my ($A, $B, $C, $D, $E, $F) =
        ( $a*$a, $b*$b, $c*$c, $b*$c*$ca, $a*$c*$cb, $a*$b*$cg );

    # The Change-of-Basis matrix, initially unity:
    my $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];

# P. M. DE WOLFF AND B. GRUBER 35
# Table 2. Theparameters D = b . c, E = a . c andF = a . b ofthe 44 lattice characters (A = a . a, B = b . b, C = c . c)
# The character of a lattice given by its Niggli form is the ﬁrst one which agrees when the 44 entries are compared with that form in the
# sequence given below. Such a logical order is not always obeyed by the widely used character numbers (ﬁrst column) which therefore
# show some reversals, e.g. 4 and 5.
# Lattice Bravais Transformation to a
# No. Type D E F symmetry type conventional basis
# A=B=C _ _

    local $, = " ";
    local $\ = "\n";

    # 1 I A/2 A/2 A/2 Cubic cF 1-11/11-1/-111
    if( abs($D-$A/2) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Cubic cF\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,-1,1], [1,1,-1], [-1,1,1] ];
    }
# 2 I D D D Rhombohedral hR 110/ 101/ 111
# 3 II 0 0 0 Cubic cP 100/ 010/001
# 5 11 -A/3 -A/3 -A/3 Cubic cI 191/110/9;;
# 4 II D D D Rhombohedral hR 110/ 101/ 111
# 6 II D* D F Tetragonal tI 011/101/110
# 7 II D* E E Tetragonal tI 101/110/011
# 8 II D* E F Orthorhombic oI 110/ 101/011

# A= B, no conditions on C _ __

# 9 I A/2 A/2 A/2 Rhombohedral hR 100/1 10/11;
# 10 I D D F Monoclinic mC 1 10/ 1 10/ 001
# 11 II 0 0 0 Tetragonal tP 100/ 010/ 001
# 12 II 0 0 -A/2 Hexagonal hP 100/(_)10/001
# 13 II 0 0 F Orthorhombic oC 110/ 110/001
# 15 II -A/2 -A/2 0 Tetragonal tI _1_Q0/010/ 112
# 16 II D* D F Orthorhombic oF 110/110/112
# 14 II D D F Monoclinic mC 110/110/go;
# 17 II D* E F Monoclinic mC 110/ 110/101

# B = C, no conditions on A _ __

# 18 I A/4 A/2 A/2 Tetragonal tI 011/ 111/100
# 19 I D A/2 A/2 Orthorhombic oI 100/011/_1_1 1
# 20 I D E E Monoclinic mC 011/011/100
# 21 II 0 0 0 Tetragonal tP 010/001 / 100

    # 22 II -B/2 0 0 Hexagonal hP 010/ 001 / 100
    if( abs($D+$B/2) < $eps && abs($E) < $eps && abs($F) < $eps ) {
        printf "22. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Hexagonal hP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,1,0], [0,0,1], [1,0,0] ];
    }
# 23 II D 0 0 Orthorhombic oC 01 1/011/ 100
# 24 II D* -A/3 -A/3 Rhombohedral hR 121/011/100
# 25 II D E E Monoclinic mC 011/011/100

# No conditions on A, B, C _ _

# 26 I A/4 A/2 A/2 Orthorhombic oF 100/120] 102
# 27 I D A/2 A/2 Monoclinic mC 120/100/011
# 28 I D A/2 2D Monoclinic mC 100/ 102/010
# 29 I D 2D A/2 Monoclinic mC 100/12(_)/001
# 30 I B/2 E 2E Monoclinic mC 010/ 012/ 100
# 31 I D E F Triclinic aP 100/ 010/ 001
# 32 II 0 0 0 Orthorhombic oP 100/ 010/ (_)01
# 40 II -B/2 0 0 Orthorhombic oC 010/912/109
# 35 II D 0 0 Monoclinic mP 010/ 100/ 001
# 36 II 0 -A/2 0 Orthorhombic oC 100/ 102/010
# 33 II 0 E 0 Monoclinic mP 100/ 010/ 001
# 38 II 0 0 -A/2 Orthorhombic oC 100/ 120/001
# 34 II 0 0 F Monoclinic mP 100/091/010
# 42 II -B/2 -A/2 0 Orthorhombic oI 199/010/112
# 41 II -B/2 E 0 Monoclinic mC 012/ 010/ 100
# 37 II D -A/2 0 Monoclinic mC 102/100/010
# 39 II D 0 -A/2 Monoclinic mC 120/100/001
# 43 II D E F Monoclinic mI 100/112/010
# 44 II D E F Triclinic aP 100/ 010/001

# *ﬂD+E+H=A+R

# ’rAs footnote * plus: |2D+ F| = B.

# it The capital letter of the symbols in this column indicates the
# centring type of the cell as obtained by the transformation in the
# last column. For this reason the standard symbols mS and OS are not
# used here.


}

1;
