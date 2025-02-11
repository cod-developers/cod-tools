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

is( Graph::Nauty::_to_dreadnaut( $g ), <<END );
n=5 g
1 4;
0 2;
1 3;
2 4;
0 3.
f=[0|1|2|3|4]
END

is( Graph::Nauty::_to_dreadnaut( $g, sub { $_[0] % 2 } ), <<END );
n=5 g
2 3;
3 4;
0 4;
0 1;
1 2.
f=[0,1,2|3,4]
END
