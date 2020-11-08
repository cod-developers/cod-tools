#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER='src/lib/perl5/COD/CIF/Parser.pm'
INPUT_NEIGHBOURS_MODULE='src/lib/perl5/COD/AtomNeighbours.pm'
INPUT_CIF='tests/inputs/lib/COD/AtomNeighbours/neighbour_list_from_cif/2006199.cif'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::AtomNeighbours::neighbour_list_from_cif() subroutine.
#**

use strict;
use warnings;

use COD::AtomNeighbours qw( neighbour_list_from_cif );
use COD::CIF::Parser qw( parse_cif );
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my( $data, $dataset );

( $data ) = parse_cif( 'tests/inputs/lib/COD/AtomNeighbours/neighbour_list_from_cif/2006199.cif' );
( $dataset ) = @$data;

my $neighbour_list = neighbour_list_from_cif( $dataset );
print Dumper $neighbour_list->{neighbours};

END_SCRIPT
