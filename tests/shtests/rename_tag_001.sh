#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PARSER='src/lib/perl5/COD/CIF/Parser.pm'
INPUT_TAG_MANAGE='src/lib/perl5/COD/CIF/Tags/Manage.pm'
INPUT_CIF='tests/inputs/generic.cif'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
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

my( $data, $dataset );

( $data ) = parse_cif( 'tests/inputs/generic.cif' );
( $dataset ) = @$data;

my $full_struct = Dumper $dataset;

print "Original struct:\n";
print $full_struct;

print "Renaming '_tag3' to '_renamed_tag3':\n";
rename_tag( $dataset, '_tag3', '_renamed_tag3' );
print diff( \$full_struct, \(Dumper $dataset) ) || "(no difference)\n";

( $data ) = parse_cif( 'tests/inputs/generic.cif' );
( $dataset ) = @$data;

print "Renaming '_tag1' to '_tag1':\n";
rename_tag( $dataset, '_tag1', '_tag1' );
print diff( \$full_struct, \(Dumper $dataset) ) || "(no difference)\n";

( $data ) = parse_cif( 'tests/inputs/generic.cif' );
( $dataset ) = @$data;

print "Renaming '_tag1' to '_tag2':\n";
rename_tag( $dataset, '_tag1', '_tag2' );
print diff( \$full_struct, \(Dumper $dataset) ) || "(no difference)\n";

END_SCRIPT
