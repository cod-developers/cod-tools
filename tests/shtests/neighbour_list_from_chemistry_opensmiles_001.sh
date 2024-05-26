#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/AtomNeighbours.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( neighbour_list_from_chemistry_opensmiles )" \
<<'END_SCRIPT'
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

# use COD::AtomNeighbours qw( neighbour_list_from_chemistry_opensmiles );
use Chemistry::OpenSMILES::Parser;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my $parser = Chemistry::OpenSMILES::Parser->new;
my @moieties = $parser->parse( 'c1ccccc1c[CH2]' );

my $neighbour_list = neighbour_list_from_chemistry_opensmiles( $moieties[0] );
print Dumper $neighbour_list->{neighbours};

END_SCRIPT
