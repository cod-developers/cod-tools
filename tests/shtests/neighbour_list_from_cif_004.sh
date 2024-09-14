#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER_MODULE=src/lib/perl5/COD/CIF/Parser.pm
INPUT_NEIGHBOURS_MODULE=src/lib/perl5/COD/AtomNeighbours.pm
INPUT_CIF=tests/inputs/1000049.cif
#END DEPEND--------------------------------------------------------------------

IMPORT_PARSER_MODULE=$(\
    echo ${INPUT_PARSER_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_NEIGHBOURS_MODULE=$(\
    echo ${INPUT_NEIGHBOURS_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

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

# use COD::AtomNeighbours qw( neighbour_list_from_cif );
# use COD::CIF::Parser qw( parse_cif );
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my $filename = $ARGV[0];

my ( $data ) = parse_cif( $filename );
my ( $dataset ) = @$data;

my $neighbour_list = neighbour_list_from_cif( $dataset );
print Dumper $neighbour_list->{atoms};

END_SCRIPT
)

perl -M"${IMPORT_PARSER_MODULE} qw( parse_cif ); " \
     -M"${IMPORT_NEIGHBOURS_MODULE} qw( neighbour_list_from_cif )" \
     -e "${TEST_SCRIPT}" "${INPUT_CIF}"
