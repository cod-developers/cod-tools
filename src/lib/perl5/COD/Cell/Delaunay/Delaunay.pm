#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Perl package implementing the Delaunay cell reduction as described
#  in the ITC vol. A and the spglib-1.6.4 library by Atsushi Togo.
#**

# To test this module, run:

# perl -MDelaunay -le '
#    @v = COD::Cell::Delaunay::Delaunay::reduce( 4.693, 4.936, 7.524, 131, 89.57, 90.67 );
#    print join(" ", map {sprintf("%5.3f",$_)} @v[0..5])'
#
# The output, as specified in the tables, should be:
# a=4.693, b=5.678, c=4.936, alpha=90, beta=90.67, gamma=90 .
#
# The actual output is:
# 4.693 4.936 5.678 90.002 90.013 90.670

package COD::Cell::Delaunay::Delaunay;

use strict;
use warnings;
use COD::Algebra::Vector qw( vdot vector_add vector_len );
use COD::Cell qw( vectors2cell );
use COD::Fractional qw( symop_ortho_from_fract );
use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    reduce
);

our $debug = 1;
my $EPSILON = 1E-5;

sub vcross($$)
{
    my ($v1, $v2) = @_;

    return [
        $v1->[1]*$v2->[2] - $v1->[2]*$v2->[1],
        $v1->[2]*$v2->[0] - $v1->[0]*$v2->[2],
        $v1->[0]*$v2->[1] - $v1->[1]*$v2->[0],
        ];
}

sub vvolume($$$)
{
    my ($v1, $v2, $v3) = @_;
    return vdot( $v1, vcross( $v2, $v3 ));
}

sub reduce
{
    my @cell = @_;

    my $eps = @cell > 6 ? pop(@cell) : $EPSILON;

    my $f2o = symop_ortho_from_fract( @cell );

    my $basis_vectors = [
        symop_vector_mul( $f2o, [1,0,0] ),
        symop_vector_mul( $f2o, [0,1,0] ),
        symop_vector_mul( $f2o, [0,0,1] )
    ];

    do {
        print "\n>>> Original basis:";
        local $\ = "\n";
        local $, = " ";
        for (@$basis_vectors) {
            print map {sprintf "%11.8f", $_ } @$_;
        }
        print ">>> Cell volume now: ", vdot($basis_vectors->[0], vcross($basis_vectors->[1],$basis_vectors->[2]));
    } if 0;

    my $reduced_vectors = Delaunay_reduction( $basis_vectors, $eps );

    my @reduced_cell = vectors2cell( @$reduced_vectors );

    return ( @reduced_cell, $reduced_vectors );
}

# Delaunay reduction is described in the International Tables for
# Crystallography, Vol. A.

# The step code coded after the spglib-1.6.4 F/LOSS library by Atsushi
# Togo.

sub Delaunay_reduction
{
    my ($basis, $epsilon) = @_;
    $epsilon = $COD::Cell::Delaunay::Delaunay::EPSILON unless defined $epsilon;
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

    do {
        print "\n>>> Reduced extended basis:";
        local $\ = "\n";
        local $, = " ";
        for (@extended_basis ) {
            print map {sprintf "%7.4f", $_ } @$_;
        }
    } if 0;

    my $reduced_basis = Delaunay_minimal_vectors( \@extended_basis, $epsilon );

    do {
        print "\n>>> Minimal basis:";
        local $\ = "\n";
        local $, = " ";
        for (@$reduced_basis ) {
            print map {sprintf "%7.4f", $_ } @$_;
        }
        print ">>> Cell volume now: ", vdot($reduced_basis->[0], vcross($reduced_basis->[1],$reduced_basis->[2]));
    } if 0;

    return $reduced_basis;
}

sub Delaunay_reduction_step
{
    my ($ebasis, $epsilon) = @_;

    do {
        print ">>> Cell volume now: ",
            vdot($ebasis->[0], vcross($ebasis->[1],$ebasis->[2]));
        print ">>> or             : ",
            vdot($ebasis->[3], vcross($ebasis->[1],$ebasis->[2]));
    } if 0;

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

sub Delaunay_minimal_vectors
{
    my ($ebasis, $epsilon) = @_;

    my @candidates = (
        @$ebasis,
        vector_add( $ebasis->[0], $ebasis->[1] ),
        vector_add( $ebasis->[1], $ebasis->[2] ),
        vector_add( $ebasis->[2], $ebasis->[0] )
    );

    do {
        print "\n>>> Candidates:";
        local $\ = "\n";
        local $, = " ";
        for (@candidates ) {
            print( map( {sprintf "%7.4f", $_ } @$_ ), "length = ", vector_len($_) );
        }
    } if 0;

    my @lengths =
        sort { $a->[0] <=> $b->[0] }
        map { [ vector_len($_), $_ ] } @candidates;

    do {
        print "\n>>> Sorted vectors:";
        local $\ = "\n";
        local $, = " ";
        my @vectors = map {$_->[1]} @lengths;
        for (@vectors ) {
            print( map( {sprintf "%7.4f", $_ } @$_ ), "length = ", vector_len($_) );
        }
    } if 0;

    # Search for a vector that forms a non-flat unit cell with the
    # first two:

    for( my $k = 2; $k < @lengths; $k ++ ) {
        my $vol = vvolume( $lengths[0][1], $lengths[1][1], $lengths[$k][1] );
        ## print ">>> \$vol = $vol\n";
        if( abs( $vol ) > $epsilon ) {
            return [ $lengths[0][1], $lengths[1][1], $lengths[$k][1] ];
        }
    }

    die "all possible Delaunay reduced cells are flat?!";
}

1;
