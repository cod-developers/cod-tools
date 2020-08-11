package Graph::Nauty;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( are_isomorphic automorphism_group_size orbits );

our $VERSION = '0.1.2'; # VERSION

require XSLoader;
XSLoader::load('Graph::Nauty', $VERSION);

sub _nauty_graph
{
    my( $graph, $color_sub, $order_sub ) = @_;

    $color_sub = sub { "$_[0]" } unless $color_sub;
    $order_sub = sub { "$_[0]" } unless $order_sub;

    my $nauty_graph = {
        nv  => scalar $graph->vertices,
        nde => scalar $graph->edges * 2, # as undirected
        e   => [],
        d   => [],
        v   => [],
    };

    my $n = 0;
    my $vertices = { map { $_ => { index => $n++, vertice => $_ } }
                     sort { $color_sub->( $a ) cmp $color_sub->( $b ) ||
                            $order_sub->( $a ) cmp $order_sub->( $b ) }
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
            push @breaks, int($color_sub->( $prev ) eq $color_sub->( $v ));
        }
        $prev = $v;
    }
    push @breaks, 0;

    return ( $nauty_graph, [ 0..$n-1 ], \@breaks, [ ( 0 ) x $n ] );
}

sub automorphism_group_size
{
    my( $graph, $color_sub ) = @_;

    my $statsblk = sparsenauty( _nauty_graph( $graph, $color_sub ),
                                1,
                                undef );
    return $statsblk->{grpsize1} * 10 ** $statsblk->{grpsize2};
}

sub orbits
{
    my( $graph, $color_sub, $order_sub ) = @_;

    my( $nauty_graph, $labels, $breaks, $orbits ) =
        _nauty_graph( $graph, $color_sub, $order_sub );
    my $statsblk = sparsenauty( $nauty_graph, $labels, $breaks, $orbits,
                                1,
                                undef );
    my @orbits;
    for my $i (0..$#{$statsblk->{orbits}}) {
        push @{$orbits[$statsblk->{orbits}[$i]]},
             $nauty_graph->{original}[$i];
    }
    return grep { defined } @orbits;
}

sub are_isomorphic
{
    my( $graph1, $graph2, $color_sub ) = @_;
    return 0 if !$graph1->could_be_isomorphic( $graph2 );

    $color_sub = sub { "$_[0]" } unless $color_sub;

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

  use Graph::Nauty qw( automorphism_group_size orbits );
  use Graph::Undirected;

  my $g = Graph::Undirected->new;

  # Create the graph here

  # Get the size of the automorphism group:
  print automorphism_group_size( $g );

  # Get automorphism group orbits:
  print orbits( $g );

=head1 DESCRIPTION

Graph::Nauty provides an interface to nauty, a set of procedures for
determining the automorphismgroup of a vertex-coloured graph, and for
testing graphs for isomorphism.

=head1 SEE ALSO

For the description of nauty refer to
E<lt>http://pallini.di.uniroma1.itE<gt>.

=head1 AUTHOR

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Andrius Merkys

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
