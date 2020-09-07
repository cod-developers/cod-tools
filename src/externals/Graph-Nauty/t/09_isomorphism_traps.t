use strict;
use warnings;
use Graph::Nauty qw(
    are_isomorphic
);
use Graph::Undirected;
use Test::More tests => 4;

my @vertices = map { { name => $_ } } 0..3;

my $A = Graph::Undirected->new;
my $B = Graph::Undirected->new;

my $C = Graph::Undirected->new;
my $D = Graph::Undirected->new;

$A->add_edges( $vertices[0], $vertices[1],
               $vertices[1], $vertices[2] );
$B->add_edges( $vertices[0], $vertices[1],
               $vertices[1], $vertices[3] );

$C->add_edges( $vertices[0], $vertices[1],
               $vertices[1], $vertices[2] );
$D->add_edges( $vertices[0], $vertices[1],
               $vertices[1], $vertices[2] );

$C->set_edge_attribute( $vertices[0], $vertices[1], 'color', 'red'  );
$D->set_edge_attribute( $vertices[0], $vertices[1], 'color', 'blue' );

ok( !are_isomorphic( $A, $B, sub { return $_[0]->{name} } ) );
ok( !are_isomorphic( $A, $C, sub { return $_[0]->{name} } ) );
ok( !are_isomorphic( $C, $A, sub { return $_[0]->{name} } ) );
ok( !are_isomorphic( $C, $D, sub { return $_[0]->{name} } ) );
