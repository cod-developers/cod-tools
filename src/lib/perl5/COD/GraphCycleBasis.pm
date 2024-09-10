#------------------------------------------------------------------------------
#$Author$
#$Revision$
#$URL$
#$Date$
#------------------------------------------------------------------------------
#*
#* Methods needed to construct fundamental cycle basis, taken from JGraphT [1]
#* implementation [2], reimplemented in Perl.
#* 
#* [1] Michail, D., Kinable, J., Naveh, B., & Sichi, J. V. (2020).
#*     Jgrapht -- a Java library for graph data structures and algorithms.
#*     ACM Transactions on Mathematical Software, 46(2).
#*     https://doi.org/10.1145/3381449
#* [2] https://github.com/jgrapht/jgrapht/blob/master/jgrapht-core/src/main/java/org/jgrapht/alg/cycle/QueueBFSFundamentalCycleBasis.java
#**

package COD::GraphCycleBasis;

use strict;
use warnings;
use Graph;

sub new {
    my ($class, %opts) = @_;
    my $self = {
        graph => Graph->new(multiedged => 1),
        edge_labels => {},
        edge_counter => 0,
    };
    bless $self, $class;
    return $self;
}

sub add_edge_with_label {
    my ($self, $u, $v, $label) = @_;
    my $edge_id = ++$self->{edge_counter};
    $self->{graph}->add_edge_by_id($u, $v, $edge_id);

    $self->{edge_labels}{$u}{$v}{$edge_id} = $label;
    $self->{edge_labels}{$v}{$u}{$edge_id} = $label;
}

sub get_edge_label {
    my ($self, $u, $v, $edge_id) = @_;
    return $self->{edge_labels}{$u}{$v}{$edge_id};
}

sub get_cycle_basis {
    my $self = shift;
    my $graph = $self->{graph};
    my $spanning_forest = $self->compute_spanning_forest();
    my %tree_edges;
    for my $f (keys %{$spanning_forest}) {
        my $edge = $spanning_forest->{$f};
        if($edge) {
            my ($source, $target, $id) = @{$edge};
            $tree_edges{$source}{$target}{$id} = 1;
        }
    }
    my @cycles;
    my @labels_collection;
    my $length = 0;
    my @edges1 = $graph->edges;
    my $all_edges = get_all_edges_with_ids($self);

    for my $e (@{$all_edges}) {
        my ($source, $target, $id) = @{$e};
        if(!$tree_edges{$source}{$target}{$id}) {
            my ($cycle, $labels) = $self->buildFundamentalCycle($e, $spanning_forest);
            push @cycles, $cycle;
            push @labels_collection, $labels;
        }
    }
    return (\@cycles, \@labels_collection);
}

sub compute_spanning_forest {
    my $self = shift;
    my $graph = $self->{graph};
    my %pred;
    my @queue;

    for my $s ($graph->vertices) {
        next if exists $pred{$s};

        $pred{$s} = undef;
        push @queue, $s;

        while(@queue) {
            my $v = shift @queue;
            my $edges_with_ids = edges_at_with_ids($self, $v);
            my @sorted_edges = sort {
                $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] || $a->[2] <=> $b->[2]
            } @{$edges_with_ids};
            for my $e (@sorted_edges) {
                my $u = _getOppositeVertex($self, $e, $v);
                if(!exists $pred{$u}) {
                    $pred{$u} = $e;
                    push @queue, $u;
                }
            }
        }
    }

    return \%pred;
}

sub buildFundamentalCycle {
    my ($self, $edge, $spanningForest) = @_;
    my ($source, $target, $id) = @{$edge};
    if($source eq $target) {
        my $weight = $self->{edge_labels}{$source}{$target}{$id};
        my %labels;
        $labels{$source}{$target}{$id} = $weight;
        my @edge = [$source, $target, $id];
        return (\@edge, \%labels);
    }

    my $label = $self->{edge_labels}{$source}{$target}{$id};
    my %path1;
    $path1{$source}{$target}{$id} = $label;
    my $current = $source;

    while($current ne $target) {
        my $edgeToParent = $spanningForest->{$current};
        last if !defined $edgeToParent;
        my $parent = _getOppositeVertex($self, $edgeToParent, $current);
        my ($source_parent, $target_parent, $id_parent) = @{$edgeToParent};
        my $label = $self->{edge_labels}{$source_parent}{$target_parent}{$id_parent};
        $path1{$source_parent}{$target_parent}{$id_parent} = $label;
        $current = $parent;
    }

    my %path2Weight;
    my @path2;

    if($current ne $target) {
        $current = $target;
        while(1) {
            my $edgeToParent = $spanningForest->{$current};
            last if !defined $edgeToParent;
            my $parent = _getOppositeVertex($self, $edgeToParent, $current);
            my ($source_parent, $target_parent, $id_parent) = @{$edgeToParent};
            if(exists $path1{$source_parent} and $path1{$source_parent}{$target_parent} and $path1{$source_parent}{$target_parent}{$id_parent}) {
                delete $path1{$source_parent}{$target_parent}{$id_parent};
            } else {
                push @path2, $edgeToParent;
                my $label = $self->{edge_labels}{$source_parent}{$target_parent}{$id_parent};
                $path2Weight{$source_parent}{$target_parent}{$id_parent} = $label;
            }
            $current = $parent;
        }
    }
    for my $source_path (keys %path1) {
        for my $target_path (keys %{ $path1{$source_path}}) {
            for my $id_path (keys %{ $path1{$source_path}{$target_path}}) {
                unshift @path2, [$source_path, $target_path, $id_path];
                my $label = $self->{edge_labels}{$source_path}{$target_path}{$id_path};
                $path2Weight{$source_path}{$target_path}{$id_path} = $label;
            }
        }
    }

    return (\@path2, \%path2Weight);
}

sub _getOppositeVertex {
    my ($self, $edge, $vertex) = @_;
    my ($source, $target) = @{$edge};
    return $source eq $vertex ? $target : $source;
}

sub get_all_edges_with_ids {
    my $self = shift;
    my $graph = $self->{graph};
    my @all_edges_with_ids;
    my %added_edges;

    for my $edge ($graph->edges) {
        my ($source, $target) = @{$edge};
        my @ids = $graph->get_multiedge_ids($source, $target);

        for my $id (@ids) {
            if(!exists $added_edges{$source}{$target}{$id}) {
                push @all_edges_with_ids, [$source, $target, $id];
                $added_edges{$source}{$target}{$id} = 1;
            }
        }
    }
    return \@all_edges_with_ids;
}
sub edges_at_with_ids {
    my ($self, $v) = @_;
    my $graph = $self->{graph};
    my @all_edges_with_ids;
    my %added_edges;

    for my $edge ($graph->edges_at($v)) {
        my ($source, $target) = @{$edge};
        my @ids = $graph->get_multiedge_ids($source, $target);

        for my $id (@ids) {
            if(!exists $added_edges{$source}{$target}{$id}) {
                push @all_edges_with_ids, [$source, $target, $id];
                $added_edges{$source}{$target}{$id} = 1;
            }
        }
    }
    return \@all_edges_with_ids;
}

sub add_vertex {
    my ($self, $v) = @_;
    return $self->{graph}->add_vertex($v);
}

sub has_vertex {
    my ($self, $v) = @_;
    return $self->{graph}->has_vertex($v);
}

1;

