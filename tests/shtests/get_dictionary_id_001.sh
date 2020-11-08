#! /bin/bash

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER='src/lib/perl5/COD/CIF/Parser.pm'
INPUT_DDL_MODULE='src/lib/perl5/COD/CIF/DDL.pm'
INPUT_CIF='tests/inputs/get_dictionary_id/ddlm/ddl.dic'
#END DEPEND--------------------------------------------------------------------

TEST_SCRIPT=$(cat <<'END_SCRIPT'
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

my $filename = $ARGV[0];

my( $data, $dataset );

( $data ) = parse_cif( $filename );

print Dumper get_dictionary_id( $data );

END_SCRIPT
)

perl -e "${TEST_SCRIPT}" "${INPUT_CIF}"
