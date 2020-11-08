#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER='src/lib/perl5/COD/CIF/Parser.pm'
INPUT_NEIGHBOURS_MODULE='src/lib/perl5/COD/AtomNeighbours.pm'
INPUT_CIF='tests/inputs/1100772.cif'
#END DEPEND--------------------------------------------------------------------

TEST_SCRIPT=$(cat <<'END_SCRIPT'
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

my $filename = $ARGV[0];

my( $data, $dataset );

( $data ) = parse_cif( $filename );
( $dataset ) = @$data;

my $neighbour_list = neighbour_list_from_cif( $dataset );
print Dumper $neighbour_list->{neighbours};

END_SCRIPT
)

perl -e "${TEST_SCRIPT}" "${INPUT_CIF}"
