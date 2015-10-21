#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Perl package implementing the Delaunay cell reduction as decribed
#  in the ITC vol. A and the spglib-1.6.4 library by Atsushi Togo.
#**

# To test this module, run:

# perl -MDelaunay -le '
#    $v = COD::Cell::Delaunay::Delaunay::reduce( 4.693, 4.936, 7.524, 131, 89.57, 90.67 );
#    print join(" ", map {sprintf("%5.3f",$_)} @{$v->[0]})'
#
# The output, as specified in the tables, should be:
# a=4.693, b=5.678, c=4.936, alpha=90, beta=90.67, gamma=90 .
#
# The actual output is:
# 4.693 4.936 5.678 90.002 90.013 90.670

package COD::Cell::Delaunay::Delaunay;

use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( reduce );

my $Pi = 4 * atan2(1,1);

use COD::Fractional qw( symop_ortho_from_fract );
use COD::Spacegroups::Symop::Algebra qw( symop_mul symop_apply );

our $debug = 1;
our $epsilon = 1E-5;

sub reduce
{
    my @cell = @_;

    my $f2o = symop_ortho_from_fract( @cell );

    my $basis_vectors = [
        symop_apply( $f2o, [1,0,0] ),
        symop_apply( $f2o, [0,1,0] ),
        symop_apply( $f2o, [0,0,1] )
    ];

    my $reduced_vectors = Delaunay_reduction( $basis_vectors );

    my @reduced_cell = (
        vlen(  $reduced_vectors->[0]),
        vlen(  $reduced_vectors->[1]),
        vlen(  $reduced_vectors->[2]),
        vangle($reduced_vectors->[1], $reduced_vectors->[2]),
        vangle($reduced_vectors->[0], $reduced_vectors->[2]),
        vangle($reduced_vectors->[0], $reduced_vectors->[1])
    );

    return ( @reduced_cell, $reduced_vectors );
}

sub vlen
{
    return sqrt( vlen2( $_[0] ));
}

sub vangle
{
    use Math::Trig;
    my ($v1, $v2) = @_;
    my $cosine = vdot( $v1, $v2 ) / ( vlen($v1) * vlen($v2) );
    return 180*Math::Trig::acos($cosine)/$Pi;
}

# Delaunau reduction is described in the International Tables for
# Crystallography, Vol. A.

# The step code coded after the spglib-1.6.4 F/LOSS library by Atsushi
# Togo.

sub Delaunay_reduction
{
    my ($basis, $epsilon) = @_;
    $epsilon = $COD::Cell::Delaunay::Delaunay::epsilon unless defined $epsilon;
    my @extended_basis =
        ( @$basis,
          [ -$basis->[0][0]-$basis->[1][0]-$basis->[2][0],
            -$basis->[0][1]-$basis->[1][1]-$basis->[2][1],
            -$basis->[0][2]-$basis->[1][2]-$basis->[2][2],
          ] );

    my $step = 0;
    while( Delaunay_reduction_step( \@extended_basis, $epsilon ) &&
           $step < 10000 ) {
        $step ++;
    }

    my $reduced_basis = Delaunay_minimal_vectors( \@extended_basis, $epsilon );
    return $reduced_basis;
}

sub Delaunay_reduction_step
{
    my ($ebasis, $epsilon) = @_;

    for( my $i = 0; $i < 4; $i ++ ) {
        for( my $j = $i + 1; $j < 4; $j ++ ) {
            my $dotprod = vdot( $ebasis->[$i], $ebasis->[$j] );
            if( $dotprod > $epsilon ) {
                for( my $k = 0; $k < 4; $k ++ ) {
                    if( $k != $i && $k != $j ) {
                        for( my $l = 0; $l < 3; $l ++ ) {
                            $ebasis->[$k][$l] += $ebasis->[$i][$l];
                        }
                    }
                }
                for( my $l = 0; $l < 3; $l ++ ) {
                    $ebasis->[$i][$l] = -$ebasis->[$i][$l];
                }
                return 1;
            }
        }
    }
    return 0;
}

sub vdot
{
    my ($v1, $v2) = @_;
    return $v1->[0]*$v2->[0] + $v1->[1]*$v2->[1] + $v1->[2]*$v2->[2];
}

sub vsum
{
    my ($v1, $v2) = @_;
    return [ $v1->[0] + $v2->[0], $v1->[1] + $v2->[1],  $v1->[2] + $v2->[2] ];
}

sub vlen2
{
    return vdot( $_[0], $_[0] );
}

sub Delaunay_minimal_vectors
{
    my ($ebasis, $epsilon) = @_;

    my @candidates = (
        @$ebasis,
        vsum( $ebasis->[0], $ebasis->[1] ),
        vsum( $ebasis->[1], $ebasis->[2] ),
        vsum( $ebasis->[2], $ebasis->[0] )
    );

    my @lengths = 
        sort { $a->[0] <=> $b->[0] }
        map { [ vlen($_), $_ ] } @candidates;

    return [ $lengths[0][1], $lengths[1][1], $lengths[2][1] ];
}

1;
