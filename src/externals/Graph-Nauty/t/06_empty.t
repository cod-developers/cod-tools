use strict;
use warnings;
use Graph::Nauty qw( automorphism_group_size );
use Graph::Undirected;
use Test::More tests => 1;

my $g = Graph::Undirected->new;

is( automorphism_group_size( $g ), 1 );
