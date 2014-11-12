#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*

# Implements cell reduction to a Niggli reduced cell using the Křivý
# & Gruber algorithm of 1976, as described in:

# Křivý, I. & Gruber, B. A unified algorithm for determining the
# reduced (Niggli) cell Acta Crystallographica Section A, 1976, 32,
# 297-298, http://dx.doi.org/10.1107/S0567739476000636

# with corrections and stability-increasing modifications from:

# Grosse-Kunstleve, R. W.; Sauter, N. K. & Adams, P. D. Numerically
# Stable Algorithms for the Computation of Reduced Unit Cells Acta
# Crystallographica. Section A, Foundations of Crystallography, 2004,
# 60, 1-6, http://dx.doi.org/10.1107/S010876730302186X

# To test, run in trunk/"

# PERL5LIB=lib/perl5/COD perl -MCell::Niggli::KG76 -e 'KG76::reduce(3,5.196,2,103+55/60,109+28/60,134+53/60)'

#**

package KG76;

use strict;
use warnings;
require Exporter;
@KG76::ISA = qw(Exporter);
@KG76::EXPORT_OK = qw( reduce );

my $Pi = 4 * atan2(1,1);

$KG76::debug = 1;

sub reduce
{
    my @cell = @_;

    my $eps = @cell > 6 ? pop(@cell) : 1E-2;

    my ($a, $b, $c, $alpha, $beta, $gamma ) =
        (@cell[0..2], map { $Pi * $_ / 180 }  @cell[3..5]);

    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);

    my ($A, $B, $C, $ksi, $eta, $dzeta) =
        ( $a*$a, $b*$b, $c*$c, 2*$b*$c*$ca, 2*$a*$c*$cb, 2*$a*$b*$cg );

    # The Change-of-Basis matrix, initially unity:
    my $CoB = [ [1,0,0], [0,1,0], [0,0,1] ];

    local $, = " ";
    local $\ = "\n";
    while(1) {
        # 1.
        if( $A - $eps > $B or
            (abs($A-$B) < $eps && abs($ksi) - $eps > abs($eta)) ) {
            printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n",
            "1.", $A, $B, $C, $ksi, $eta, $dzeta, " " if $KG76::debug;
            my ($tmp1, $tmp2) = ($A, $ksi);
            ($A, $ksi) = ($B, $eta);
            ($B, $eta) = ($tmp1, $tmp2);
        }
        # 2.
        if( $B - $eps > $C or
            (abs($B-$C) < $eps && abs($eta) - $eps > abs($dzeta)) ) {
            printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n",
            "2.", $A, $B, $C, $ksi, $eta, $dzeta, " " if $KG76::debug;
            my ($tmp1, $tmp2) = ($B, $eta);
            ($B, $eta) = ($C, $dzeta);
            ($C, $dzeta) = ($tmp1, $tmp2);
            next
        }
        # 3.
        if( $ksi * $eta * $dzeta - $eps > 0 ) {
            printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n",
            "3.", $A, $B, $C, $ksi, $eta, $dzeta, " " if $KG76::debug;
            ($ksi, $eta, $dzeta) = map {abs} ($ksi, $eta, $dzeta);
        }
        # 4.
        if( !($ksi * $eta * $dzeta - $eps > 0) ) {
            printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n",
            "4.", $A, $B, $C, $ksi, $eta, $dzeta, " " if $KG76::debug;
            ($ksi, $eta, $dzeta) = map {-abs($_)} ($ksi, $eta, $dzeta);
        }
        # 5.
        ## print "5:", abs($ksi-$B) - $eps;
        if( abs($ksi) - $eps > $B or 
            (abs($ksi-$B) < $eps && 2 * $eta < $dzeta - $eps) or
            (abs($ksi+$B) < $eps && $dzeta < -$eps) ) {
            printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n",
            "5.", $A, $B, $C, $ksi, $eta, $dzeta, " " if $KG76::debug;
            my $sign_ksi = $ksi > 0 ? 1 : -1;
            $C = $B + $C - $ksi * $sign_ksi;
            $eta -= $dzeta * $sign_ksi;
            $ksi -= 2 * $B * $sign_ksi;
            next
        }
        # 6.
        if( abs($eta) - $eps > $A or
            (abs($eta-$A) < $eps && 2 * $ksi < $dzeta - $eps) or
            (abs($eta+$A) < $eps && $dzeta < -$eps) ) {
            printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n",
            "6.", $A, $B, $C, $ksi, $eta, $dzeta, " " if $KG76::debug;
            my $sign_eta = $eta > 0 ? 1 : -1;
            $C = $A + $C - $eta * $sign_eta;
            $ksi -= $dzeta * $sign_eta;
            $eta -= 2 * $A * $sign_eta;
            next
        }
        # 7.
        ## print "7:", abs($dzeta+$A);
        if( abs($dzeta) - $eps > $A or
            (abs($dzeta-$A) < $eps && 2 * $ksi < $eta - $eps) or
            (abs($dzeta+$A) < $eps && $eta < -$eps) ) {
            printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n",
            "7.", $A, $B, $C, $ksi, $eta, $dzeta, " " if $KG76::debug;
            my $sign_dzeta = $dzeta > 0 ? 1 : -1;
            $B = $A + $B - $dzeta * $sign_dzeta;
            $ksi -= $eta * $sign_dzeta;
            $dzeta -= 2 * $A * $sign_dzeta;
            next;
        }
        # 8.
        if( $ksi + $eta + $dzeta + $A + $B < -$eps or
            (abs($ksi + $eta + $dzeta + $A + $B) < $eps && 
             2*($A+$eta) + $dzeta - $eps > 0) ) {
            printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n",
            "8.", $A, $B, $C, $ksi, $eta, $dzeta, " " if $KG76::debug;
            $C = $A + $B + $C + $ksi + $eta + $dzeta;
            $ksi = 2*$B + $ksi + $dzeta;
            $eta = 2*$A + $eta + $dzeta;
            next;
        }
        last
    }
    if( $KG76::debug ) {
        use POSIX;
        printf "%s  %6.2f %6.2f %6.2f %6.2f %6.2f %6.2f\n", 
        "  ", $A, $B, $C, $ksi, $eta, $dzeta, " ";
        print "CELL", sqrt($A), sqrt($B), sqrt($C),
        180*acos($ksi/(2*sqrt($B)*sqrt($C)))/$Pi,
        180*acos($eta/(2*sqrt($A)*sqrt($C)))/$Pi,
        180*acos($dzeta/(2*sqrt($A)*sqrt($B)))/$Pi;
    }
}

1;
