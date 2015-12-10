#!/usr/bin/perl

use strict;
use warnings;
use Chemistry::Mol;
use Chemistry::File::SMILES;
use COD::AtomNeighbours qw( neighbour_list_from_chemistry_mol );
use COD::Serialise qw( serialiseRef );

my $mol = Chemistry::Mol->parse( "C1cc1(=O)[O-]", format => "smiles" );
serialiseRef( neighbour_list_from_chemistry_mol( $mol ) );
