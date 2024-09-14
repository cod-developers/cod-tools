#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER_MODULE=src/lib/perl5/COD/CIF/Parser.pm
INPUT_MANAGE_MODULE=src/lib/perl5/COD/CIF/Tags/Manage.pm
INPUT_CIF=tests/inputs/generic.cif
#END DEPEND--------------------------------------------------------------------

IMPORT_PARSER_MODULE=$(\
    echo ${INPUT_PARSER_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_MANAGE_MODULE=$(\
    echo ${INPUT_MANAGE_MODULE} | \
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
#* Unit test for the COD::CIF::Tags::Manage::rename_tag() subroutine.
#**

use strict;
use warnings;

use COD::CIF::Parser qw( parse_cif );
use COD::CIF::Tags::Manage qw( rename_tag );

use Data::Dumper;
use Text::Diff;

$Data::Dumper::Sortkeys = 1;

my $filename = $ARGV[0];

my( $data, $dataset );

( $data ) = parse_cif( $filename );
( $dataset ) = @$data;

my $full_struct = Dumper $dataset;

print "Original struct:\n";
print $full_struct;

print "Renaming '_tag3' to '_renamed_tag3':\n";
rename_tag( $dataset, '_tag3', '_renamed_tag3' );
print diff( \$full_struct, \(Dumper $dataset) ) || "(no difference)\n";

( $data ) = parse_cif( $filename );
( $dataset ) = @$data;

print "Renaming '_tag1' to '_tag1':\n";
rename_tag( $dataset, '_tag1', '_tag1' );
print diff( \$full_struct, \(Dumper $dataset) ) || "(no difference)\n";

( $data ) = parse_cif( $filename );
( $dataset ) = @$data;

print "Renaming '_tag1' to '_tag2':\n";
rename_tag( $dataset, '_tag1', '_tag2' );
print diff( \$full_struct, \(Dumper $dataset) ) || "(no difference)\n";

END_SCRIPT
)

perl -M"${IMPORT_PARSER_MODULE} qw( parse_cif )" \
     -M"${IMPORT_MANAGE_MODULE} qw( rename_tag )" \
     -e "${TEST_SCRIPT}" "${INPUT_CIF}"
