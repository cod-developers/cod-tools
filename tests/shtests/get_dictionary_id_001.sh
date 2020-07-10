#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER='src/lib/perl5/COD/CIF/Parser.pm'
INPUT_DDL_MODULE='src/lib/perl5/COD/CIF/DDL.pm'
INPUT_CIF='tests/inputs/DDLm_3.11.09.dic'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::DDL::get_dictionary_id() subroutine.
#**

use strict;
use warnings;

use COD::CIF::Parser qw( parse_cif );
use COD::CIF::DDL qw( get_dictionary_id );
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my( $data, $dataset );

( $data ) = parse_cif( 'tests/inputs/DDLm_3.11.09.dic' );

print Dumper get_dictionary_id( $data );

END_SCRIPT
