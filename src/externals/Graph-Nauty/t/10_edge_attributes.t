use strict;
use warnings;
use Graph::Nauty;
use Graph::Undirected;
use Test::More tests => 2;

my $g = Graph::Undirected->new;

my $n = 5;
for (0..$n-1) {
    $g->add_edge( $_, ($_ - 1) % $n );
    $g->add_edge( $_, ($_ + 1) % $n );
}

my $nauty_graph;

$g->set_edge_attribute( 0, 1, 'color', 'green' );
$g->set_edge_attribute( 1, 2, 'color', 'orange' );

( $nauty_graph ) = Graph::Nauty::_nauty_graph( $g );
is( scalar $nauty_graph->{nv}, 7 );

$g->set_edge_attribute( 1, 2, 'color', 'green' );

( $nauty_graph ) = Graph::Nauty::_nauty_graph( $g );
is( scalar $nauty_graph->{nv}, 7 );
