package Graph::Nauty;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    are_isomorphic
    automorphism_group_size
    orbits
    orbits_are_same
);

our $VERSION = '0.3.1'; # VERSION

require XSLoader;
XSLoader::load('Graph::Nauty', $VERSION);

use Graph::Nauty::EdgeNode;
use Graph::Undirected;
use Scalar::Util qw(blessed);

sub _cmp
{
    my( $a, $b, $sub ) = @_;

    if( blessed $a && $a->isa( Graph::Nauty::EdgeNode:: ) &&
        blessed $b && $b->isa( Graph::Nauty::EdgeNode:: ) ) {
        return "$a" cmp "$b";
    } elsif( blessed $a && $a->isa( Graph::Nauty::EdgeNode:: ) ) {
        return 1;
    } elsif( blessed $b && $b->isa( Graph::Nauty::EdgeNode:: ) ) {
        return -1;
    } else {
        return $sub->( $a ) cmp $sub->( $b );
    }
}

sub _nauty_graph
{
    my( $graph, $color_sub, $order_sub ) = @_;

    $color_sub = sub { "$_[0]" } unless $color_sub;
    $order_sub = sub { "$_[0]" } unless $order_sub;

    if( grep { $graph->has_edge_attributes( @$_ ) } $graph->edges ) {
        # colored bonds detected, need to transform the graph
        my $graph_now = Graph::Undirected->new( vertices => [ $graph->vertices ] );
        for my $edge ( $graph->edges ) {
            if( $graph->has_edge_attributes( @$edge ) ) {
                my $edge_node = Graph::Nauty::EdgeNode->new( $graph->get_edge_attributes( @$edge ) );
                $graph_now->add_edge( $edge->[0], $edge_node );
                $graph_now->add_edge( $edge_node, $edge->[1] );
            } else {
                $graph_now->add_edge( @$edge );
            }
        }
        $graph = $graph_now;
    }

    my $nauty_graph = {
        nv  => scalar $graph->vertices,
        nde => scalar $graph->edges * 2, # as undirected
        e   => [],
        d   => [],
        v   => [],
    };

    my $n = 0;
    my $vertices = { map { $_ => { index => $n++, vertice => $_ } }
                     sort { _cmp( $a, $b, $color_sub ) ||
                            _cmp( $a, $b, $order_sub ) }
                         $graph->vertices };

    my @breaks;
    my $prev;
    for my $v (map { $vertices->{$_}{vertice} }
               sort { $vertices->{$a}{index} <=>
                      $vertices->{$b}{index} } keys %$vertices) {
        push @{$nauty_graph->{d}}, scalar $graph->neighbours( $v );
        push @{$nauty_graph->{v}}, scalar @{$nauty_graph->{e}};
        push @{$nauty_graph->{original}}, $v;
        for (sort { $vertices->{$a}{index} <=> $vertices->{$b}{index} }
                  $graph->neighbours( $v )) {
            push @{$nauty_graph->{e}}, $vertices->{$_}{index};
        }
        if( defined $prev ) {
            push @breaks, int(_cmp( $prev, $v, $color_sub ) == 0);
        }
        $prev = $v;
    }
    push @breaks, 0;

    return ( $nauty_graph, [ 0..$n-1 ], \@breaks );
}

sub automorphism_group_size
{
    my( $graph, $color_sub ) = @_;

    my $statsblk = sparsenauty( _nauty_graph( $graph, $color_sub ),
                                undef );
    return $statsblk->{grpsize1} * 10 ** $statsblk->{grpsize2};
}

sub orbits
{
    my( $graph, $color_sub, $order_sub ) = @_;

    my( $nauty_graph, $labels, $breaks ) =
        _nauty_graph( $graph, $color_sub, $order_sub );
    my $statsblk = sparsenauty( $nauty_graph, $labels, $breaks,
                                { getcanon => 1 } );

    my $orbits = [];
    for my $i (@{$statsblk->{lab}}) {
        next if blessed $nauty_graph->{original}[$i] &&
             $nauty_graph->{original}[$i]->isa( Graph::Nauty::EdgeNode:: );
        if( !@$orbits || $statsblk->{orbits}[$i] !=
            $statsblk->{orbits}[$orbits->[-1][0]] ) {
            push @$orbits, [ $i ];
        } else {
            push @{$orbits->[-1]}, $i;
        }
    }

    return map { [ map { $nauty_graph->{original}[$_] } @$_ ] }
               @$orbits;
}

sub are_isomorphic
{
    my( $graph1, $graph2, $color_sub ) = @_;
    return 0 if !$graph1->could_be_isomorphic( $graph2 );

    my @nauty_graph1 = _nauty_graph( $graph1, $color_sub );
    my @nauty_graph2 = _nauty_graph( $graph2, $color_sub );

    return 0 if $nauty_graph1[0]->{nv} != $nauty_graph2[0]->{nv};

    my $statsblk1 = sparsenauty( @nauty_graph1, { getcanon => 1 } );
    my $statsblk2 = sparsenauty( @nauty_graph2, { getcanon => 1 } );

    for my $i (0..$nauty_graph1[0]->{nv}-1) {
        my $j = $statsblk1->{lab}[$i];
        my $k = $statsblk2->{lab}[$i];
        return 0 if _cmp( $nauty_graph1[0]->{original}[$j],
                          $nauty_graph2[0]->{original}[$k],
                          $color_sub ) != 0;
    }

    return aresame_sg( $statsblk1->{canon}, $statsblk2->{canon} );
}

sub orbits_are_same
{
    my( $graph1, $graph2, $color_sub ) = @_;
    return 0 if !$graph1->could_be_isomorphic( $graph2 );

    my @orbits1 = orbits( $graph1, $color_sub );
    my @orbits2 = orbits( $graph2, $color_sub );

    return 0 if scalar @orbits1 != scalar @orbits2;

    for my $i (0..$#orbits1) {
        return 0 if scalar @{$orbits1[$i]} != scalar @{$orbits2[$i]};
        return 0 if $color_sub->( $orbits1[$i]->[0] ) ne
                    $color_sub->( $orbits2[$i]->[0] );
    }

    return 1;
}

1;
__END__

=head1 NAME

Graph::Nauty - Perl bindings for nauty

=head1 SYNOPSIS

  use Graph::Nauty qw( are_isomorphic automorphism_group_size orbits );
  use Graph::Undirected;

  my $A = Graph::Undirected->new;
  my $B = Graph::Undirected->new;

  # Create graphs here

  # Get the size of the automorphism group:
  print automorphism_group_size( $A );

  # Get automorphism group orbits:
  print orbits( $A );

  # Check whether two graphs are isomorphs:
  print are_isomorphic( $A, $B );

=head1 DESCRIPTION

Graph::Nauty provides an interface to nauty, a set of procedures for
determining the automorphism group of a vertex-coloured graph, and for
testing graphs for isomorphism.

Currently Graph::Nauty only supports
L<Graph::Undirected|Graph::Undirected>, that is, it does not handle
directed graphs. Both colored vertices and edges are accounted for when
determining equivalence classes.

=head1 INSTALLING

Building and installing Graph::Nauty from source requires shared library
and C headers for nauty, which can be downloaded from
L<https://users.cecs.anu.edu.au/~bdm/nauty/>. Both the library and C
headers have to be installed to locations visible by Perl's C compiler.

=head1 SEE ALSO

For the description of nauty refer to L<http://pallini.di.uniroma1.it>.

=head1 AUTHOR

Andrius Merkys, L<mailto:merkys@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Andrius Merkys

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
