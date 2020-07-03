#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES=src/lib/perl5/COD/AtomNeighbours.pm
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'

use strict;
use warnings;
use COD::AtomNeighbours qw( neighbour_list_to_cif_datablock );
use COD::CIF::Tags::Print qw( print_cif );

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

my $datablock = neighbour_list_to_cif_datablock( $neighbour_list );
print_cif( $datablock );

END_SCRIPT
