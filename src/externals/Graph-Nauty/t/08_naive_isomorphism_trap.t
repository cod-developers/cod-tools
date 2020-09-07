use strict;
use warnings;
use Graph::Nauty qw(
    are_isomorphic
    orbits
    orbits_are_same
);
use Graph::Undirected;
use Test::More tests => 3;

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

is( join( ',', map { scalar @$_ } orbits( $g1,
                                          sub { return $_[0]->{type} },
                                          sub { return $_[0]->{index} } ) ),
    join( ',', map { scalar @$_ } orbits( $g2,
                                          sub { return $_[0]->{type} },
                                          sub { return $_[0]->{index} } ) ) );
ok( are_isomorphic(  $g1, $g2, sub { return $_[0]->{type} } ) );
ok( orbits_are_same( $g1, $g2, sub { return $_[0]->{type} } ) );
