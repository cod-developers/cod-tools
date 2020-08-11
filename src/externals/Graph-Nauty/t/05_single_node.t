use strict;
use warnings;
use Graph::Nauty qw( automorphism_group_size orbits );
use Graph::Undirected;
use Test::More tests => 2;

my $g = Graph::Undirected->new;
$g->add_vertex( 0 );

is( automorphism_group_size( $g ), 1 );
is( scalar orbits( $g ), 1 );
