#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_NEIGHBOURS_MODULE=src/lib/perl5/COD/AtomNeighbours.pm
INPUT_SERIALISE_MODULE=src/lib/perl5/COD/Serialise.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_NEIGHBOURS_MODULE=$(\
    echo ${INPUT_NEIGHBOURS_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_SERIALISE_MODULE=$(\
    echo ${INPUT_SERIALISE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_NEIGHBOURS_MODULE} qw( neighbour_list_from_chemistry_mol )" \
     -M"${IMPORT_SERIALISE_MODULE} qw( serialiseRef )" \
<<'END_SCRIPT'

use strict;
use warnings;

use COD::AtomNeighbours qw( neighbour_list_from_chemistry_mol );
use COD::Serialise qw( serialiseRef );

use Chemistry::Mol;
use Chemistry::File::SMILES;

my $mol = Chemistry::Mol->parse( "c1ccccc1", format => "smiles" );
serialiseRef( neighbour_list_from_chemistry_mol( $mol ) );

END_SCRIPT
