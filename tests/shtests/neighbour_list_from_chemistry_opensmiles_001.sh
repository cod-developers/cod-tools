#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_NEIGHBOURS_MODULE='src/lib/perl5/COD/AtomNeighbours.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::AtomNeighbours::neighbour_list_from_chemistry_opensmiles() subroutine.
#**

use strict;
use warnings;

use COD::AtomNeighbours qw( neighbour_list_from_chemistry_opensmiles );
use COD::CIF::Parser qw( parse_cif );
use Chemistry::OpenSMILES::Parser;

my $parser = Chemistry::OpenSMILES::Parser->new;
my @moieties = $parser->parse( 'c1ccccc1' );

my $neighbour_list = neighbour_list_from_chemistry_opensmiles( $moieties[0] );

local $\ = "\n";
print scalar @{$neighbour_list->{atoms}};
print scalar @{$neighbour_list->{neighbours}};

END_SCRIPT
