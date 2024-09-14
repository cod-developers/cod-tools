#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_NEIGHBOURS_MODULE=src/lib/perl5/COD/AtomNeighbours.pm
INPUT_PRINT_MODULE=src/lib/perl5/COD/CIF/Tags/Print.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_NEIGHBOURS_MODULE=$(\
    echo ${INPUT_NEIGHBOURS_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_PRINT_MODULE=$(\
    echo ${INPUT_PRINT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_NEIGHBOURS_MODULE} qw( neighbour_list_to_cif_datablock )" \
     -M"${IMPORT_PRINT_MODULE} qw( print_cif )" \
<<'END_SCRIPT'

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
