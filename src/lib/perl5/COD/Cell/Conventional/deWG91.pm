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

package COD::Cell::Conventional::deWG91;

use strict;
use warnings;
use COD::Cell qw( vectors2cell );
use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul symop_transpose );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    conventional_cell
);

my $PI = 4 * atan2(1,1);
my $EPSILON = 1E-2;

$COD::Cell::Conventional::deWG91::debug = 1;

# Check for Type I cell:
sub is_type_I
{
    my ($D, $E, $F, $eps) = @_;
    return $D >= $eps && $E >= $eps && $F >= $eps;
}

# Check for Type II cell:
sub is_type_II
{
    return not &is_type_I
}

sub conventional_cell
{
    my @cell = @_;

    my $eps = @cell > 6 ? pop(@cell) : $EPSILON;

    my ($a, $b, $c, $alpha, $beta, $gamma ) =
        (@cell[0..2], map { $PI * $_ / 180 }  @cell[3..5]);

    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);

    my ($A, $B, $C, $D, $E, $F) =
        ( $a*$a, $b*$b, $c*$c, $b*$c*$ca, $a*$c*$cb, $a*$b*$cg );

    # The Change-of-Basis matrix, initially unity:
    my $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];

    # Crystal system compatible with the cell:
    my $crystal_system;

# P. M. DE WOLFF AND B. GRUBER 35
# Table 2. The parameters D = b . c, E = a . c and F = a . b of the 44 lattice characters (A = a . a, B = b . b, C = c . c)
#
# The character of a lattice given by its Niggli form is the first one
# which agrees when the 44 entries are compared with that form in the
# sequence given below. Such a logical order is not always obeyed by
# the widely used character numbers (first column) which therefore show
# some reversals, e.g. 4 and 5.
#
# Lattice Bravais Transformation to a
# No. Type D E F symmetry type conventional basis

    local $, = " ";
    local $\ = "\n";

    # A = B = C

    # 1 I A/2 A/2 A/2 Cubic cF 1-11/11-1/-111
    if( is_type_I( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps && abs($A-$C) < $eps && abs($B-$C) < $eps &&
        abs($D-$A/2) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "1. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Cubic cF\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,-1,1], [1,1,-1], [-1,1,1] ];
        $crystal_system = "cF";
    }
    # 2 I D D D Rhombohedral hR 1-10/-101/-1-1-1
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps && abs($A-$C) < $eps && abs($B-$C) < $eps &&
        abs($E-$D) < $eps && abs($F-$D) < $eps ) {
        printf "2. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Rhombohedral hR\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,-1,0], [-1,0,1], [-1,-1,-1] ];
        $crystal_system = "hR";
    }
    # 3 II 0 0 0 Cubic cP 100/010/001
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps && abs($A-$C) < $eps && abs($B-$C) < $eps &&
        abs($D) < $eps && abs($E) < $eps && abs($F) < $eps ) {
        printf "3. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Cubic cP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];
        $crystal_system = "cP";
    }
    # 5 II -A/3 -A/3 -A/3 Cubic cI 101/110/011
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps && abs($A-$C) < $eps && abs($B-$C) < $eps &&
        abs($D+$A/3) < $eps && abs($E+$A/3) < $eps && abs($F+$A/3) < $eps ) {
        printf "5. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Cubic cI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,1], [1,1,0], [0,1,1] ];
        $crystal_system = "cI";
    }
    # 4 II D D D Rhombohedral hR 1-10/-101/-1-1-1
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps && abs($A-$C) < $eps && abs($B-$C) < $eps &&
        abs($E-$D) < $eps && abs($F-$D) < $eps ) {
        printf "4. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Rhombohedral hR\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,-1,0], [-1,0,1], [-1,-1,-1] ];
        $crystal_system = "hR";
    }
    # 6 II D* D F Tetragonal tI 011/101/110
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps && abs($A-$C) < $eps && abs($B-$C) < $eps &&
        abs($E-$D) < $eps &&
        abs( 2*abs($D+$E+$F) - $A - $B ) < $eps ) {
        printf "6. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,1,1], [1,0,1], [1,1,0] ];
        $crystal_system = "tI";
    }
    # 7 II D* E E Tetragonal tI 101/110/011
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps && abs($A-$C) < $eps && abs($B-$C) < $eps &&
        abs($F-$E) < $eps &&
        abs( 2*abs($D+$E+$F) - $A - $B ) < $eps ) {
        printf "7. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,1], [1,1,0], [0,1,1] ];
        $crystal_system = "tI";
    }
    # 8 II D* E F Orthorhombic oI -1-10/-10-1/0-1-1
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps && abs($A-$C) < $eps && abs($B-$C) < $eps &&
        abs($F-$F) < $eps &&
        abs( 2*abs($D+$E+$F) - $A - $B ) < $eps ) {
        printf "8. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,-1,0], [-1,0,-1], [0,-1,-1] ];
        $crystal_system = "oI";
    }

    # A = B, no conditions on C

    # 9 I A/2 A/2 A/2 Rhombohedral hR 100/-110/-1-13
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($D-$A/2) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "9. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Rhombohedral hR\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [-1,1,0], [-1,-1,3] ];
        $crystal_system = "hR";
    }
    # 10 I D D F Monoclinic mC 110/1-10/00-1
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($E-$D) < $eps ) {
        printf "10. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,1,0], [1,-1,0], [0,0,-1] ];
        $crystal_system = "mC";
    }
    # 11 II 0 0 0 Tetragonal tP 100/010/001
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($D) < $eps && abs($E) < $eps && abs($F) < $eps ) {
        printf "11. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];
        $crystal_system = "tP";
    }
    # 12 II 0 0 -A/2 Hexagonal hP 100/010/001
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($D) < $eps && abs($E) < $eps && abs($F+$A/2) < $eps ) {
        printf "12. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Hexagonal hP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];
        $crystal_system = "hP";
    }
    # 13 II 0 0 F Orthorhombic oC 110/-110/001
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($D) < $eps && abs($E) < $eps ) {
        printf "13. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,1,0], [-1,1,0], [0,0,1] ];
        $crystal_system = "oC";
    }
    # 15 II -A/2 -A/2 0 Tetragonal tI 100/010/112
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($D+$A/2) < $eps && abs($E+$A/2) < $eps && abs($F) < $eps ) {
        printf "15. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [0,1,0], [1,1,2] ];
        $crystal_system = "tI";
    }
    # 16 II D* D F Orthorhombic oF -1-10/1-10/112
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($E-$D) < $eps &&
        abs( 2*abs($D+$E+$F) - $A - $B ) < $eps ) {
        printf "16. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oF\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,-1,0], [1,-1,0], [1,1,2] ];
        $crystal_system = "oF";
    }
    # 14 II D D F Monoclinic mC 110/-110/001;
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($E-$D) < $eps ) {
        printf "14. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,1,0], [-1,1,0], [0,0,1] ];
        $crystal_system = "mC";
    }
    # 17 II D* E F Monoclinic mC 1-10/110/-10-1
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($A-$B) < $eps &&
        abs($F-$F) < $eps &&
        abs( 2*abs($D+$E+$F) - $A - $B ) < $eps ) {
        printf "17. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,-1,0], [1,1,0], [-1,0,-1] ];
        $crystal_system = "mC";
    }

# B = C, no conditions on A

    # 18 I A/4 A/2 A/2 Tetragonal tI 0-11/1-1-1/100
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($B-$C) < $eps &&
        abs($D-$A/4) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "18. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,-1,1], [1,-1,-1], [1,0,0] ];
        $crystal_system = "tI";
    }
    # 19 I D A/2 A/2 Orthorhombic oI -100/0-11/-111
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($B-$C) < $eps &&
        abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "19. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,0,0], [0,-1,1], [-1,1,1] ];
        $crystal_system = "oI";
    }
    # 20 I D E E Monoclinic mC 011/01-1/-100
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($B-$C) < $eps &&
        abs($F-$E) < $eps ) {
        printf "20. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,1,1], [0,1,-1], [-1,0,0] ];
        $crystal_system = "mC";
    }
    # 21 II 0 0 0 Tetragonal tP 010/001/100
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($B-$C) < $eps &&
        abs($D) < $eps && abs($E) < $eps && abs($F) < $eps ) {
        printf "21. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Tetragonal tP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,1,0], [0,0,1], [1,0,0] ];
        $crystal_system = "tP";
    }
    # 22 II -B/2 0 0 Hexagonal hP 010/001/100
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($B-$C) < $eps &&
        abs($D+$B/2) < $eps && abs($E) < $eps && abs($F) < $eps ) {
        printf "22. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Hexagonal hP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,1,0], [0,0,1], [1,0,0] ];
        $crystal_system = "hP";
    }
    # 23 II D 0 0 Orthorhombic oC 011/0-11/100
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($B-$C) < $eps &&
        abs($E) < $eps && abs($F) < $eps ) {
        printf "23. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,1,1], [0,-1,1], [1,0,0] ];
        $crystal_system = "oC";
    }
    # 24 II D* -A/3 -A/3 Rhombohedral hR 121/0-11/100
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($B-$C) < $eps &&
        abs($E+$A/3) < $eps && abs($F+$A/3) < $eps &&
        abs( 2*abs($D+$E+$F) - $A - $B ) < $eps ) {
        printf "24. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Rhombohedral hR\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,2,1], [0,-1,1], [1,0,0] ];
        $crystal_system = "hR";
    }
    # 25 II D E E Monoclinic mC 011/0-11/100
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($B-$C) < $eps &&
        abs($F-$E) < $eps ) {
        printf "25. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,1,1], [0,-1,1], [1,0,0] ];
        $crystal_system = "mC";
    }

    # No conditions on A, B, C

    # 26 I A/4 A/2 A/2 Orthorhombic oF 100/-120/-102
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($D-$A/4) < $eps && abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "26. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oF\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [-1,2,0], [-1,0,2] ];
        $crystal_system = "oF";
    }
    # 27 I D A/2 A/2 Monoclinic mC -120/-100/0-11
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($E-$A/2) < $eps && abs($F-$A/2) < $eps ) {
        printf "27. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,2,0], [-1,0,0], [0,-1,1] ];
        $crystal_system = "mC";
    }
    # 28 I D A/2 2D Monoclinic mC -100/-102/010
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($E-$A/2) < $eps && abs($F-2*$D) < $eps ) {
        printf "28. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,0,0], [-1,0,2], [0,1,0] ];
    }
    # 29 I D 2D A/2 Monoclinic mC 100/1-20/00-1
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($E-2*$D) < $eps && abs($F-$A/2) < $eps ) {
        printf "29. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [1,-2,0], [0,0,-1] ];
        $crystal_system = "mC";
    }
    # 30 I B/2 E 2E Monoclinic mC 010/01-2/-100
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($D-$B/2) < $eps && abs($F-2*$E) < $eps ) {
        printf "30. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,1,0], [0,1,-2], [-1,0,0] ];
        $crystal_system = "mC";
    }
    # 31 I D E F Triclinic aP 100/010/001
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($F-$F) < $eps ) {
        printf "31. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Triclinic aP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];
        $crystal_system = "aP";
    }
    # 32 II 0 0 0 Orthorhombic oP 100/010/001
    elsif( is_type_I( $D, $E, $F, $eps ) &&
        abs($D) < $eps && abs($E) < $eps && abs($F) < $eps ) {
        printf "32. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];
        $crystal_system = "oP";
    }
    # 40 II -B/2 0 0 Orthorhombic oC 0-10/012/-100
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($D+$B/2) < $eps && abs($E) < $eps && abs($F) < $eps ) {
        printf "40. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,-1,0], [0,1,2], [-1,0,0] ];
        $crystal_system = "oC";
    }
    # 35 II D 0 0 Monoclinic mP 0-10/-100/00-1
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($E) < $eps && abs($F) < $eps ) {
        printf "35. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,-1,0], [-1,0,0], [0,0,-1] ];
        $crystal_system = "mP";
    }
    # 36 II 0 -A/2 0 Orthorhombic oC 100/-10-2/010
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($D) < $eps && abs($E+$A/2) < $eps && abs($F) < $eps ) {
        printf "36. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [-1,0,-2], [0,1,0] ];
        $crystal_system = "oC";
    }
    # 33 II 0 E 0 Monoclinic mP 100/010/001
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($D) < $eps && abs($F) < $eps ) {
        printf "33. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];
        $crystal_system = "mP";
    }
    # 38 II 0 0 -A/2 Orthorhombic oC -100/120/00-1
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($D) < $eps && abs($E) < $eps && abs($F+$A/2) < $eps ) {
        printf "38. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,0,0], [1,2,0], [0,0,-1] ];
        $crystal_system = "oC";
    }
    # 34 II 0 0 F Monoclinic mP -100/00-1/0-10
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($D) < $eps && abs($E) < $eps ) {
        printf "34. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,0,0], [0,0,-1], [0,-1,0] ];
        $crystal_system = "mP";
    }
    # 42 II -B/2 -A/2 0 Orthorhombic oI -100/0-10/112
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($D+$B/2) < $eps && abs($E+$A/2) < $eps && abs($F) < $eps ) {
        printf "42. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Orthorhombic oI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,0,0], [0,-1,0], [1,1,2] ];
        $crystal_system = "oI";
    }
    # 41 II -B/2 E 0 Monoclinic mC 0-1-2/0-10/-100
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($D+$B/2) < $eps && abs($F) < $eps ) {
        printf "41. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [0,-1,-2], [0,-1,0], [-1,0,0] ];
        $crystal_system = "mC";
    }
    # 37 II D -A/2 0 Monoclinic mC 102/100/010
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($E+$A/2) < $eps && abs($F) < $eps ) {
        printf "37. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,2], [1,0,0], [0,1,0] ];
        $crystal_system = "mC";
    }
    # 39 II D 0 -A/2 Monoclinic mC -1-20/-100/00-1
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs($E) < $eps && abs($F+$A/2) < $eps ) {
        printf "39. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mC\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,-2,0], [-1,0,0], [0,0,-1] ];
        $crystal_system = "mC";
    }
    # 43 II D E F Monoclinic mI -100/-1-1-2/0-10
    elsif( is_type_II( $D, $E, $F, $eps ) &&
        abs( 2*abs($D+$E+$F) - $A - $B ) < $eps &&
        abs( abs(2*$D+$F) - $B ) < $eps ) {
        printf "43. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Monoclinic mI\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [-1,0,0], [-1,-1,-2], [0,-1,0] ];
        $crystal_system = "mI";
    } else {
        # 44 II D E F Triclinic aP 100/010/001
        printf "44. %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f Triclinic aP\n",
        $A, $B, $C, $D, $E, $F if $COD::Cell::Conventional::deWG91::debug;
        $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];
        $crystal_system = "aP";
    }

    use COD::Fractional qw(symop_ortho_from_fract);

    my $f2o = symop_ortho_from_fract( @cell );
    my $new_basis = [
        symop_vector_mul( $CoB, [1,0,0] ),
        symop_vector_mul( $CoB, [0,1,0] ),
        symop_vector_mul( $CoB, [0,0,1] )
    ];
    my $new_basis_ortho = [
        symop_vector_mul( $f2o, [ $new_basis->[0][0],
                                  $new_basis->[1][0],
                                  $new_basis->[2][0] ] ),
        symop_vector_mul( $f2o, [ $new_basis->[0][1],
                                  $new_basis->[1][1],
                                  $new_basis->[2][1] ] ),
        symop_vector_mul( $f2o, [ $new_basis->[0][2],
                                  $new_basis->[1][2],
                                  $new_basis->[2][2] ] )
    ];
    my @new_cell = vectors2cell( @$new_basis_ortho );

    return ( @new_cell, $CoB, $crystal_system );
}

1;
