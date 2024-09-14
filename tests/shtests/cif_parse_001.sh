#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Parser/Bison.pm
INPUT_CIF=tests/inputs/cif_parse/missing-closing-double-quote.cif
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

TEST_SCRIPT=$(cat <<'END_SCRIPT'
use strict;
use warnings;

# use COD::CIF::Parser::Bison;

my $filename = $ARGV[0];

my $parser = new COD::CIF::Parser::Bison;
$parser->Run( $filename,
              { fix_errors => 0 } );
END_SCRIPT
)

perl -M"${IMPORT_MODULE}" \
     -e "${TEST_SCRIPT}" "${INPUT_CIF}"
