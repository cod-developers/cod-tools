use strict;
use warnings;
use Graph::Nauty;
use Test::More tests => 4;

my $n = 5;
my @e = ( 0 ) x $n;
for (0..$n-1) {
    $e[2*$_]   = ($_ + $n - 1) % $n; # edge i->i-1
    $e[2*$_+1] = ($_ + $n + 1) % $n; # edge i->i+1
}

my $sparse = {
    nv  => $n,
    nde => 2 * $n,
    v   => [ map { 2 * $_ } 0..$n-1 ],
    d   => [ ( 2 ) x $n ],
    e   => \@e,
};

my $statsblk = Graph::Nauty::sparsenauty( $sparse,
                                          [ 0..$n-1 ],
                                          [ ( 1 ) x $n ],
                                          [ ( 0 ) x $n ],
                                          1,
                                          undef );
ok( $statsblk->{errstatus} == 0 );
ok( $statsblk->{grpsize1}  == 10 );
ok( $statsblk->{grpsize2}  == 0 );
ok( $statsblk->{numorbits} == 1 );
