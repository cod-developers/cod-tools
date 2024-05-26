#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/AtomNeighbours.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( neighbour_list_from_chemistry_mol neighbour_list_to_chemistry_mol )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::AtomNeighbours::neighbour_list_to_chemistry_mol
#* subroutine. The output may be imprecise, but represents "best effort".
#**

use strict;
use warnings;

# use COD::AtomNeighbours qw(
#     neighbour_list_from_chemistry_mol
#     neighbour_list_to_chemistry_mol
# );

use Chemistry::File::SMILES;
use Chemistry::Mol;

my $mol1 = Chemistry::Mol->parse( "C1cc1(=O)[O-]", format => "smiles" );
my $neighbours = neighbour_list_from_chemistry_mol( $mol1 );
my $mol2 = neighbour_list_to_chemistry_mol( $neighbours );
$mol2->write( "/dev/stdout", format => "smiles" );
print "\n";

END_SCRIPT
