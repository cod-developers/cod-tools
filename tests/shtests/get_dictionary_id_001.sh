#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER_MODULE=src/lib/perl5/COD/CIF/Parser.pm
INPUT_DDL_MODULE=src/lib/perl5/COD/CIF/DDL.pm
INPUT_CIF=tests/inputs/get_dictionary_id/ddlm/ddl.dic
#END DEPEND--------------------------------------------------------------------

IMPORT_PARSER_MODULE=$(\
    echo ${INPUT_PARSER_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_DDL_MODULE=$(\
    echo ${INPUT_DDL_MODULE} | \
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
#* Unit test for the COD::CIF::DDL::get_dictionary_id() subroutine.
#**

use strict;
use warnings;

# use COD::CIF::Parser qw( parse_cif );
# use COD::CIF::DDL qw( get_dictionary_id );
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my $filename = $ARGV[0];

my( $data, $dataset );

( $data ) = parse_cif( $filename );

print Dumper get_dictionary_id( $data );

END_SCRIPT
)

perl -M"${IMPORT_PARSER_MODULE} qw( parse_cif )" \
     -M"${IMPORT_DDL_MODULE} qw( get_dictionary_id )" \
     -e "${TEST_SCRIPT}" "${INPUT_CIF}"
