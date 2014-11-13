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
# A = B = C

    local $, = " ";
    local $\ = "\n";

    # 1 I A/2 A/2 A/2 Cubic cF 1-11/11-1/-111
    if( abs($D-$A/2) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Cubic cF\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,-1,1], [1,1,-1], [-1,1,1] ];
    }
    # 2 I D D D Rhombohedral hR 1-10/-101/-1-1-1
    if( abs($D-$D) < $eps && abs($E-$D) < $eps && abs($F-$D) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Rhombohedral hR\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,-1,0], [-1,0,1], [-1,-1,-1] ];
    }
    # 3 II 0 0 0 Cubic cP 100/010/001
    if( abs($D-0) < $eps && abs($E-0) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Cubic cP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [0,1,0], [0,0,1] ];
    }
    # 5 11 -A/3 -A/3 -A/3 Cubic cI 101/110/011
    if( abs($D+$A/3) < $eps && abs($E+$A/3) < $eps && abs($F+$A/3) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Cubic cI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,1], [1,1,0], [0,1,1] ];
    }
    # 4 II D D D Rhombohedral hR 1-10/-101/-1-1-1
    if( abs($D-$D) < $eps && abs($E-$D) < $eps && abs($F-$D) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Rhombohedral hR\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,-1,0], [-1,0,1], [-1,-1,-1] ];
    }
    # 6 II D* D F Tetragonal tI 011/101/110
    if( abs($D-$D) < $eps && abs($E-$D) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,1,1], [1,0,1], [1,1,0] ];
    }
    # 7 II D* E E Tetragonal tI 101/110/011
    if( abs($D-$D) < $eps && abs($E-$E) < $eps && abs($F-$E) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,1], [1,1,0], [0,1,1] ];
    }
    # 8 II D* E F Orthorhombic oI -1-10/-10-1/0-1-1
    if( abs($D-$D) < $eps && abs($E-$E) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,-1,0], [-1,0,-1], [0,-1,-1] ];
    }

# A = B, no conditions on C

    # 9 I A/2 A/2 A/2 Rhombohedral hR 100/-110/-1-13
    if( abs($D-$A/2) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Rhombohedral hR\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [-1,1,0], [-1,-1,3] ];
    }
    # 10 I D D F Monoclinic mC 110/1-10/00-1
    if( abs($D-$D) < $eps && abs($E-$D) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,1,0], [1,-1,0], [0,0,-1] ];
    }
    # 11 II 0 0 0 Tetragonal tP 100/010/001
    if( abs($D-0) < $eps && abs($E-0) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [0,1,0], [0,0,1] ];
    }
    # 12 II 0 0 -A/2 Hexagonal hP 100/010/001
    if( abs($D-0) < $eps && abs($E-0) < $eps && abs($F+$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Hexagonal hP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [0,1,0], [0,0,1] ];
    }
    # 13 II 0 0 F Orthorhombic oC 110/-110/001
    if( abs($D-0) < $eps && abs($E-0) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,1,0], [-1,1,0], [0,0,1] ];
    }
    # 15 II -A/2 -A/2 0 Tetragonal tI 100/010/112
    if( abs($D+$A/2) < $eps && abs($E+$A/2) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [0,1,0], [1,1,2] ];
    }
    # 16 II D* D F Orthorhombic oF -1-10/1-10/112
    if( abs($D-$D) < $eps && abs($E-$D) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oF\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,-1,0], [1,-1,0], [1,1,2] ];
    }
    # 14 II D D F Monoclinic mC 110/-110/001;
    if( abs($D-$D) < $eps && abs($E-$D) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,1,0], [-1,1,0], [0,0,1] ];
    }
    # 17 II D* E F Monoclinic mC 1-10/110/-10-1
    if( abs($D-$D) < $eps && abs($E-$E) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,-1,0], [1,1,0], [-1,0,-1] ];
    }

# B = C, no conditions on A

    # 18 I A/4 A/2 A/2 Tetragonal tI 0-11/1-1-1/100
    if( abs($D-$A/4) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,-1,1], [1,-1,-1], [1,0,0] ];
    }
    # 19 I D A/2 A/2 Orthorhombic oI -100/0-11/-111
    if( abs($D-$D) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,0,0], [0,-1,1], [-1,1,1] ];
    }
    # 20 I D E E Monoclinic mC 011/01-1/-100
    if( abs($D-$D) < $eps && abs($E-$E) < $eps && abs($F-$E) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,1,1], [0,1,-1], [-1,0,0] ];
    }
    # 21 II 0 0 0 Tetragonal tP 010/001/100
    if( abs($D-0) < $eps && abs($E-0) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,1,0], [0,0,1], [1,0,0] ];
    }
    # 22 II -B/2 0 0 Hexagonal hP 010/001/100
    if( abs($D+$B/2) < $eps && abs($E) < $eps && abs($F) < $eps ) {
        printf "22. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Hexagonal hP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,1,0], [0,0,1], [1,0,0] ];
    }
    # 23 II D 0 0 Orthorhombic oC 011/0-11/100
    if( abs($D-$D) < $eps && abs($E-0) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,1,1], [0,-1,1], [1,0,0] ];
    }
    # 24 II D* -A/3 -A/3 Rhombohedral hR 121/0-11/100
    if( abs($D-$D) < $eps && abs($E+$A/3) < $eps && abs($F+$A/3) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Rhombohedral hR\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,2,1], [0,-1,1], [1,0,0] ];
    }
    # 25 II D E E Monoclinic mC 011/0-11/100
    if( abs($D-$D) < $eps && abs($E-$E) < $eps && abs($F-$E) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,1,1], [0,-1,1], [1,0,0] ];
    }

# No conditions on A, B, C

    # 26 I A/4 A/2 A/2 Orthorhombic oF 100/-120/-102
    if( abs($D-$A/4) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oF\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [-1,2,0], [-1,0,2] ];
    }
    # 27 I D A/2 A/2 Monoclinic mC -120/-100/0-11
    if( abs($D-$D) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,2,0], [-1,0,0], [0,-1,1] ];
    }
    # 28 I D A/2 2D Monoclinic mC -100/-102/010
    if( abs($D-$D) < $eps && abs($E-$A/2) < $eps && abs($F-2*$D) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,0,0], [-1,0,2], [0,1,0] ];
    }
    # 29 I D 2D A/2 Monoclinic mC 100/1-20/00-1
    if( abs($D-$D) < $eps && abs($E-2*$D) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [1,-2,0], [0,0,-1] ];
    }
    # 30 I B/2 E 2E Monoclinic mC 010/01-2/-100
    if( abs($D-$B/2) < $eps && abs($E-$E) < $eps && abs($F-2*$E) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,1,0], [0,1,-2], [-1,0,0] ];
    }
    # 31 I D E F Triclinic aP 100/010/001
    if( abs($D-$D) < $eps && abs($E-$E) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Triclinic aP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [0,1,0], [0,0,1] ];
    }
    # 32 II 0 0 0 Orthorhombic oP 100/010/001
    if( abs($D-0) < $eps && abs($E-0) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [0,1,0], [0,0,1] ];
    }
    # 40 II -B/2 0 0 Orthorhombic oC 0-10/012/-100
    if( abs($D+$B/2) < $eps && abs($E-0) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,-1,0], [0,1,2], [-1,0,0] ];
    }
    # 35 II D 0 0 Monoclinic mP 0-10/-100/00-1
    if( abs($D-$D) < $eps && abs($E-0) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,-1,0], [-1,0,0], [0,0,-1] ];
    }
    # 36 II 0 -A/2 0 Orthorhombic oC 100/-10-2/010
    if( abs($D-0) < $eps && abs($E+$A/2) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [-1,0,-2], [0,1,0] ];
    }
    # 33 II 0 E 0 Monoclinic mP 100/010/001
    if( abs($D-0) < $eps && abs($E-$E) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [0,1,0], [0,0,1] ];
    }
    # 38 II 0 0 -A/2 Orthorhombic oC -100/120/00-1
    if( abs($D-0) < $eps && abs($E-0) < $eps && abs($F+$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,0,0], [1,2,0], [0,0,-1] ];
    }
    # 34 II 0 0 F Monoclinic mP -100/00-1/0-10
    if( abs($D-0) < $eps && abs($E-0) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,0,0], [0,0,-1], [0,-1,0] ];
    }
    # 42 II -B/2 -A/2 0 Orthorhombic oI -100/0-10/112
    if( abs($D+$B/2) < $eps && abs($E+$A/2) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,0,0], [0,-1,0], [1,1,2] ];
    }
    # 41 II -B/2 E 0 Monoclinic mC 0-1-2/0-10/-100
    if( abs($D+$B/2) < $eps && abs($E-$E) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [0,-1,-2], [0,-1,0], [-1,0,0] ];
    }
    # 37 II D -A/2 0 Monoclinic mC 102/100/010
    if( abs($D-$D) < $eps && abs($E+$A/2) < $eps && abs($F-0) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,2], [1,0,0], [0,1,0] ];
    }
    # 39 II D 0 -A/2 Monoclinic mC -1-20/-100/00-1
    if( abs($D-$D) < $eps && abs($E-0) < $eps && abs($F+$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,-2,0], [-1,0,0], [0,0,-1] ];
    }
    # 43 II D E F Monoclinic mI -100/-1-1-2/0-10
    if( abs($D-$D) < $eps && abs($E-$E) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mI\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [-1,0,0], [-1,-1,-2], [0,-1,0] ];
    }
    # 44 II D E F Triclinic aP 100/010/001
    if( abs($D-$D) < $eps && abs($E-$E) < $eps && abs($F-$F) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Triclinic aP\n",
        $A, $B, $C, $D, $E, $F if $KG76::debug;
        return [ [1,0,0], [0,1,0], [0,0,1] ];
    }
}

1;
