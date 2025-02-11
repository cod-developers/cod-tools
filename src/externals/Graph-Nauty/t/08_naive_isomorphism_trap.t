use strict;
use warnings;
use Graph::Nauty qw(
    are_isomorphic
    canonical_order
    orbits
);
use Graph::Undirected;
use Test::More tests => 5;

my @v1 = ( { index => 0, type => 0 },
           { index => 1, type => 1 },
           { index => 2, type => 0 },
           { index => 3, type => 0 } );
my @v2 = ( { index => 0, type => 0 },
           { index => 1, type => 0 },
           { index => 2, type => 1 },
           { index => 3, type => 0 } );

my $g1 = Graph::Undirected->new;
my $g2 = Graph::Undirected->new;

$g1->add_edge( $v1[0], $v1[1] );
$g1->add_edge( $v1[0], $v1[3] );
$g1->add_edge( $v1[2], $v1[1] );
$g1->add_edge( $v1[2], $v1[3] );

$g2->add_edge( $v2[0], $v2[1] );
$g2->add_edge( $v2[0], $v2[3] );
$g2->add_edge( $v2[2], $v2[1] );
$g2->add_edge( $v2[2], $v2[3] );

is join( ',', map { scalar @$_ } orbits( $g1,
                                         sub { $_[0]->{type} },
                                         sub { $_[0]->{index} } ) ),
   '2,1,1';
is join( ',', map { scalar @$_ } orbits( $g2,
                                         sub { $_[0]->{type} },
                                         sub { $_[0]->{index} } ) ),
   '1,2,1';
ok are_isomorphic(  $g1, $g2, sub { $_[0]->{type} } );

is( join( ',', map { $_->{index} }
                   canonical_order( $g1,
                                    sub { $_[0]->{type} },
                                    sub { $_[0]->{index} } ) ),
    '3,0,2,1' );
is( join( ',', map { $_->{index} }
                   canonical_order( $g2,
                                    sub { $_[0]->{type} },
                                    sub { $_[0]->{index} } ) ),
    '0,1,3,2' );
