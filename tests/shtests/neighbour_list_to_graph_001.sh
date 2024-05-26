#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/AtomNeighbours.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( neighbour_list_to_graph )" \
<<'END_SCRIPT'

use strict;
use warnings;

use COD::AtomNeighbours qw( neighbour_list_to_graph );

my $neighbour_list = {
    atoms => [
        {
            name  => 'C1',
            index => 0,
            attached_hydrogens => 3,
        },
        {
            name  => 'C2',
            index => 1,
            attached_hydrogens => 1,
        },
        {
            name  => 'O1',
            index => 2,
            attached_hydrogens => 0,
        },
        {
            name => 'O2',
            index => 3,
            attached_hydrogens => 2,
        },
    ],
    neighbours => [
        [ 1 ], [ 0, 2 ], [ 1 ], [],
    ],
};

my $graph = neighbour_list_to_graph( $neighbour_list );
my $atoms = $neighbour_list->{atoms};

$\ = "\n";
print scalar $graph->vertices;
print scalar $graph->edges;

print $graph->is_connected + 0;

print $graph->has_edge( $atoms->[0], $atoms->[1] ) + 0;
print $graph->has_edge( $atoms->[0], $atoms->[3] ) + 0;

END_SCRIPT
