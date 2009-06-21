#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
#       Convert orthogonal coordinates into fractional and back
#-----------------------------------------------------------------------

package Fractional;

use strict;
require Exporter;
@Fractional::ISA = qw(Exporter);
@Fractional::EXPORT = qw(
    fract2ortho ortho2fract 
    ortho_from_fract fract_from_ortho
    symop_ortho_from_fract symop_fract_from_ortho
);

## my $Pi = 3.1415926;
my $Pi = atan2(1,1)*4;

sub fract2ortho
{
    &ortho_from_fract
}

sub ortho_from_fract
{
    my @cell = @{$_[0]}; shift;
    my ($a, $b, $c) = @cell[0..2];
    my ($x_frac, $y_frac, $z_frac) = @_;
    my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);
    my $sg = sin($gamma);
    
    my $x = $x_frac * $a + $y_frac * $b * $cg + $z_frac * $c * $cb;
    my $y = $y_frac * $b * $sg + $z_frac * $c * ($ca-$cb*$cg)/$sg;
    my $z = $z_frac * $c * sqrt($sg**2 - $cb**2 - $ca**2 + 2*$ca*$cb*$cg)/$sg;
    return ($x, $y, $z);
}

sub ortho2fract
{
    &fract_from_ortho
}

sub fract_from_ortho
{
    my @cell = @{$_[0]}; shift;
    my ($a, $b, $c) = @cell[0..2];
    my ($x, $y, $z) = @_;
    my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);
    my $sg = sin($gamma);
    my $ctg = $cg/$sg;
    my $D = sqrt($sg**2 - $cb**2 - $ca**2 + 2*$ca*$cb*$cg);

    my $fract_x = $x/$a - $y*$ctg/$a + $z*$ctg*($ca - 2*$cb*$cg)/($a*$D);
    my $fract_y = $y/($b*$sg) - $z*($ca - $cb*$cg)/($b*$D*$sg);
    my $fract_z = $z*$sg/($c*$D);

    return ($fract_x, $fract_y, $fract_z);
}

sub symop_ortho_from_fract
{
    my @cell = @_;
    my ($a, $b, $c) = @cell[0..2];
    my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);
    my $sg = sin($gamma);

    return [
        [ $a, $b*$cg, $c*$cb               ],
        [  0, $b*$sg, $c*($ca-$cb*$cg)/$sg ],
        [  0,      0, $c*sqrt($sg*$sg-$ca*$ca-$cb*$cb+2*$ca*$cb*$cg)/$sg ]
    ];
}

sub symop_fract_from_ortho
{
    my @cell = @_;
    my ($a, $b, $c) = @cell[0..2];
    my ($alpha, $beta, $gamma) = map {$Pi * $_ / 180} @cell[3..5];
    my ($ca, $cb, $cg) = map {cos} ($alpha, $beta, $gamma);
    my $sg = sin($gamma);
    my $ctg = $cg/$sg;
    my $D = sqrt($sg**2 - $cb**2 - $ca**2 + 2*$ca*$cb*$cg);

    return [
        [ 1/$a, -(1/$a)*$ctg,  ($ca*$cg-$cb)/($a*$D)     ],
        [    0,   1/($b*$sg), -($ca-$cb*$cg)/($b*$D*$sg) ],
        [    0,            0,                $sg/($c*$D) ],
    ];
}
