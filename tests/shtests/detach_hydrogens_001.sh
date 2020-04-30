#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES=src/lib/perl5/COD/AtomNeighbours.pm
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'

use strict;
use warnings;
use COD::AtomNeighbours qw( detach_hydrogens );
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

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
            name  => 'O',
            index => 2,
            attached_hydrogens => 0,
        }
    ],
    neighbours => [
        [ 1 ], [ 0, 2 ], [ 1 ],
    ],
};

detach_hydrogens( $neighbour_list );
print Dumper $neighbour_list;

END_SCRIPT
