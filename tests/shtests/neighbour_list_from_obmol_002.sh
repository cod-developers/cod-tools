#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/Escape.pm \
               src/lib/perl5/COD/AtomNeighbours.pm \
               src/lib/perl5/COD/Serialise.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'

use strict;
use warnings;
use Chemistry::OpenBabel;
use COD::AtomNeighbours qw( neighbour_list_from_chemistry_openbabel_obmol );
use COD::Serialise qw( serialiseRef );

my $obMol = new Chemistry::OpenBabel::OBMol;
my $obConversion = new Chemistry::OpenBabel::OBConversion;
$obConversion->SetInFormat( "smi" );
$obConversion->ReadString( $obMol, "c1ccccc1" );
serialiseRef( neighbour_list_from_chemistry_openbabel_obmol( $obMol ) );

END_SCRIPT
