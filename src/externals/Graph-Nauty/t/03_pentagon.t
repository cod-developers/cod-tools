use strict;
use warnings;
use Graph::Nauty qw( automorphism_group_size );
use Graph::Undirected;
use Test::More tests => 4;

my $g = Graph::Undirected->new;

my $n = 5;
for (0..$n-1) {
    $g->add_edge( $_, ($_ - 1) % $n );
    $g->add_edge( $_, ($_ + 1) % $n );
}

is( automorphism_group_size( $g ), 1 );
is( automorphism_group_size( $g, sub { return 0 } ), 10 );
is( automorphism_group_size( $g, sub { return $_[0] < 2 } ), 2 );
is( automorphism_group_size( $g, sub { return $_[0] < 2 ? $_[0] : 2 } ), 1 );
