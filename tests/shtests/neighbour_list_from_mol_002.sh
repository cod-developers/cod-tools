#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/Escape.pm \
               src/lib/perl5/COD/AtomNeighbours.pm \
               src/lib/perl5/COD/Serialise.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'

use strict;
use warnings;
use Chemistry::Mol;
use Chemistry::File::SMILES;
use COD::AtomNeighbours qw( neighbour_list_from_chemistry_mol );
use COD::Serialise qw( serialiseRef );

my $mol = Chemistry::Mol->parse( "c1ccccc1", format => "smiles" );
serialiseRef( neighbour_list_from_chemistry_mol( $mol ) );

END_SCRIPT
