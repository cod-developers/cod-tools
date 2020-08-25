use strict;
use warnings;
use Graph::Nauty qw(
    are_isomorphic
    automorphism_group_size
    orbits_are_same
);
use Graph::Undirected;
use Test::More tests => 7;

my $g1 = Graph::Undirected->new;
my $g2 = Graph::Undirected->new;

my $n = 5;
for (0..$n-1) {
    $g1->add_edge( $_, ($_ + 1) % $n );
    $g2->add_edge( $_, ($_ + 1) % $n ) if $_ != $n-1;
}

is( automorphism_group_size( $g1 ), 1 );
is( automorphism_group_size( $g1, sub { return 0 } ), 10 );
is( automorphism_group_size( $g1, sub { return $_[0] < 2 } ), 2 );
is( automorphism_group_size( $g1, sub { return $_[0] < 2 ? $_[0] : 2 } ), 1 );

ok( !orbits_are_same( $g1, $g2 ) );
ok( !orbits_are_same( $g1, $g2, sub { return 0 } ) );
ok( !are_isomorphic( $g1, $g2 ) );
