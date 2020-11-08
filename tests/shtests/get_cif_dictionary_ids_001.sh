#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER='src/lib/perl5/COD/CIF/Parser.pm'
INPUT_DDL_MODULE='src/lib/perl5/COD/CIF/DDL.pm'
INPUT_CIF='tests/inputs/4308312-audit-dict-name.cif'
#END DEPEND--------------------------------------------------------------------

TEST_SCRIPT=$(cat <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::DDL::get_cif_dictionary_ids() subroutine.
#**

use strict;
use warnings;

use COD::CIF::Parser qw( parse_cif );
use COD::CIF::DDL qw( get_cif_dictionary_ids );
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my $filename = $ARGV[0];

my( $data, $dataset );

( $data ) = parse_cif( $filename );
( $dataset ) = @$data;

print Dumper get_cif_dictionary_ids( $dataset );

END_SCRIPT
)

perl -e "${TEST_SCRIPT}" "${INPUT_CIF}"
