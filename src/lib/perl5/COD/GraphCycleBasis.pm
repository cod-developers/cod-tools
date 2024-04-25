package COD::GraphCycleBasis;

use strict;
use warnings;
use Graph;

sub new {
    my ($class, %opts) = @_;
    my $self = {
        graph => Graph->new(%opts),
        edge_labels => {},
    };
    bless $self, $class;
    return $self;
}

sub add_edge_with_label {
    my ($self, $u, $v, $label) = @_;
    $self->{graph}->add_edge($u, $v);
    $self->{edge_labels}{$u}{$v} = $label;
    $self->{edge_labels}{$v}{$u} = $label;
}

sub get_edge_label {
    my ($self, $u, $v) = @_;
    return $self->{edge_labels}{$u}{$v};
}

sub get_cycle_basis {
    my $self = shift;
    my $graph = $self->{graph};
    my $spanning_forest = $self->compute_spanning_forest();
    #my %tree_edges = map { $_ => 1 } values %$spanning_forest;
    my %tree_edges;
    for my $f (keys %$spanning_forest) {
        my $edge = $spanning_forest->{$f};
        if($edge) {
            my ($source, $target) = @$edge;
            $tree_edges{$source}{$target} = 1;
        }
    }
    my @cycles;
    my @labels_collection;
    my $length = 0;

    for my $e ($graph->edges) {
        my ($source, $target) = @$e;
        unless($tree_edges{$source}{$target}) {
            my ($cycle, $labels) = $self->buildFundamentalCycle($e, $spanning_forest);
            push(@cycles, $cycle);
            push(@labels_collection, $labels);
        }
    }
    return (\@cycles, \@labels_collection);
}

sub compute_spanning_forest {
    my $self = shift;
    my $graph = $self->{graph};
    my %pred;
    my @queue;

    foreach my $s ($graph->vertices) {
        next if exists $pred{$s};

        $pred{$s} = undef;
        push(@queue, $s);

        while(@queue) {
            my $v = shift(@queue);

            for my $e (sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } $graph->edges_at($v)) {
                my $u = _getOppositeVertex($self, $e, $v);
                unless(exists $pred{$u}) {
                    $pred{$u} = $e;
                    push(@queue, $u);
                }
            }
            #foreach my $u ($graph->neighbours($v)) {
            #    unless (exists $pred{$u}) {
            #        my ($edge) = grep { $_->[0] eq $u || $_->[1] eq $u } $graph->edges_at($v);
            #        $pred{$u} = $edge;
            #        push(@queue, $u);
            #    }
            #}
        }
    }

    return \%pred;
}

sub buildFundamentalCycle {
    my ($self, $edge, $spanningForest) = @_;
    my ($source, $target) = @$edge;
    if($source eq $target) {
        my $weight = $self->{edge_labels}{$source}{$target};
        my %labels = ($edge=>$weight);
        return [[$edge], \%labels];
    }

    #my @path1 = ($edge);
    my $label = $self->{edge_labels}{$source}{$target};
    my %path1;# = ($edge => $label);
    $path1{$source}{$target} = $label;
    my $current = $source;

    while($current ne $target) {
        my $edgeToParent = $spanningForest->{$current};
        last unless defined $edgeToParent;
        my $parent = _getOppositeVertex($self, $edgeToParent, $current);
        my $label = $self->{edge_labels}{$current}{$parent};
        my ($source, $target) = @$edgeToParent;
        $path1{$source}{$target} = $label;
        #push(@path1, $edgeToParent);
        #$path1_set{$edgeToParent} = 1;
        $current = $parent;
    }

    my %path2Weight;
    my @path2;

    unless($current eq $target) {
        $current = $target;
        while(1) {
            my $edgeToParent = $spanningForest->{$current};
            last unless defined $edgeToParent;
            my $parent = _getOppositeVertex($self, $edgeToParent, $current);
            my ($source, $target) = @$edgeToParent;
            if($path1{$source}{$target}) {
                delete $path1{$source}{$target}; 
            } else {
                push(@path2, $edgeToParent);
                my $label = $self->{edge_labels}{$current}{$parent};
                $path2Weight{$source}{$target} = $label;
            }
            $current = $parent;
        }
    }
    for my $source (keys %path1) {
        for my $target (keys %{ $path1{$source}}) {
            unshift(@path2, [$source, $target]);
            my $label = $self->{edge_labels}{$source}{$target};
            $path2Weight{$source}{$target} = $label;
        }
        #unshift(@path2, $e);
        #my ($source, $target) = @$e;
        #my $label = $self->{edge_labels}{$source}{$target};
        #$path2Weight{$e} = $label;
    }

    return (\@path2, \%path2Weight);
}

sub _getOppositeVertex {
    my ($self, $edge, $vertex) = @_;
    my ($source, $target) = @$edge;
    return $source eq $vertex ? $target : $source;
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

