use strict;
use warnings;
use Graph::Nauty qw(
    are_isomorphic
    automorphism_group_size
    orbits
);
use Graph::Undirected;
use Test::More tests => 1;

# Graph taken from "Refinement: equitable partition" section from:
# https://pallini.di.uniroma1.it/Introduction.html

my $g = Graph::Undirected->new;

$g->add_cycle( 1..8 );
$g->add_edge( 1, 7 );
$g->add_edge( 2, 6 );
$g->add_edge( 3, 5 );
$g->add_edge( 4, 8 );

is scalar orbits( $g, sub { '' } ), 3;
