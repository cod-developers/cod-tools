use strict;
use warnings;
use Graph::Nauty qw( are_isomorphic automorphism_group_size );
use Graph::Undirected;
use Test::More tests => 2;

my $g = Graph::Undirected->new;
my $h = Graph::Undirected->new;

is( automorphism_group_size( $g ), 1 );
is( are_isomorphic( $g, $h ), 1 );
