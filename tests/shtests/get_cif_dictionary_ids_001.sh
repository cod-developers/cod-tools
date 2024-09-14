#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER_MODULE=src/lib/perl5/COD/CIF/Parser.pm
INPUT_DDL_MODULE=src/lib/perl5/COD/CIF/DDL.pm
INPUT_CIF=tests/inputs/4308312-audit-dict-name.cif
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
#* Unit test for the COD::CIF::DDL::get_cif_dictionary_ids() subroutine.
#**

use strict;
use warnings;

# use COD::CIF::Parser qw( parse_cif );
# use COD::CIF::DDL qw( get_cif_dictionary_ids );
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

my $filename = $ARGV[0];

my( $data, $dataset );

( $data ) = parse_cif( $filename );
( $dataset ) = @$data;

print Dumper get_cif_dictionary_ids( $dataset );

END_SCRIPT
)

perl -M"${IMPORT_PARSER_MODULE} qw( parse_cif )" \
     -M"${IMPORT_DDL_MODULE}    qw( get_cif_dictionary_ids )" \
     -e "${TEST_SCRIPT}" "${INPUT_CIF}"
