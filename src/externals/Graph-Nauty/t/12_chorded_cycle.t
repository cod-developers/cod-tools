use strict;
use warnings;
use Graph::Nauty;
use Test::More tests => 5;

# Graph taken from "Refinement: equitable partition" section from:
# https://pallini.di.uniroma1.it/Introduction.html

my $n = 8;
my @e;
for (0..$n-1) {
    push @e, ($_ + $n - 1) % $n, ($_ + $n + 1) % $n; # circle edges
    push @e, 6 if $_ == 0;
    push @e, 5 if $_ == 1;
    push @e, 4 if $_ == 2;
    push @e, 7 if $_ == 3;
    push @e, 2 if $_ == 4;
    push @e, 1 if $_ == 5;
    push @e, 0 if $_ == 6;
    push @e, 3 if $_ == 7;
}


my $sparse = {
    nv  => $n,
    nde => 3 * $n,
    v   => [ map { 3 * $_ } 0..$n-1 ],
    d   => [ ( 3 ) x $n ],
    e   => \@e,
};

my $statsblk = Graph::Nauty::sparsenauty( $sparse,
                                          [ 0..$n-1 ],
                                          [ ( 1 ) x $n ],
                                          undef,
                                          0 );
is $statsblk->{errstatus}, 0;
is $statsblk->{grpsize1},  4;
is $statsblk->{grpsize2},  0;
is $statsblk->{numorbits}, 3;
is join( ',', @{$statsblk->{orbits}} ), '0,1,0,3,0,1,0,3';
