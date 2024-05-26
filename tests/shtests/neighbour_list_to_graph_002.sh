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
