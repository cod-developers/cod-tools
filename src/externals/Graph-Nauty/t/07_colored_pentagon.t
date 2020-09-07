use strict;
use warnings;
use Graph::Nauty qw( orbits );
use Graph::Undirected;
use Test::More tests => 2;

my $g = Graph::Undirected->new;

my $n = 5;
for (0..$n-1) {
    $g->add_edge( $_, ($_ - 1) % $n );
    $g->add_edge( $_, ($_ + 1) % $n );
}

$g->set_edge_attribute( 0, 1, 'color', 'green' );
is( scalar orbits( $g, sub { return 0 } ), 3 );

$g->set_edge_attribute( 1, 2, 'color', 'orange' );
is( scalar orbits( $g, sub { return 0 } ), 5 );
