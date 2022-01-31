#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE='src/lib/perl5/COD/AtomNeighbours.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
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

use Chemistry::File::SMILES;
use Chemistry::Mol;
use COD::AtomNeighbours qw(
    neighbour_list_from_chemistry_mol
    neighbour_list_to_chemistry_mol
);

my $mol1 = Chemistry::Mol->parse( "C1cc1(=O)[O-]", format => "smiles" );
my $neighbours = neighbour_list_from_chemistry_mol( $mol1 );
my $mol2 = neighbour_list_to_chemistry_mol( $neighbours );
$mol2->write( "/dev/stdout", format => "smiles" );
print "\n";

END_SCRIPT
