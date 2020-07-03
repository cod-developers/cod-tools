#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES=src/lib/perl5/COD/AtomNeighbours.pm
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'

use strict;
use warnings;
use COD::AtomNeighbours qw( neighbour_list_to_graph );
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my $neighbour_list = {
    atoms => [
        {
            name  => 'He',
            index => 0,
        },
    ],
    neighbours => [],
};

my $graph = neighbour_list_to_graph( $neighbour_list );
my $atoms = $neighbour_list->{atoms};

$\ = "\n";
print scalar $graph->vertices;
print scalar $graph->edges;

print $graph->is_connected + 0;

END_SCRIPT
