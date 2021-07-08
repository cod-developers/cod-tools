#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Tags/Print.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Print::print_single_tag_and_value()
#* subroutine. Tests the way the subroutine behaves when the data item
#* value consists of a single string with no whitespaces and a semicolon
#* prefix (i.e. ';very-long-string-...' that does not fit into the same
#* line as the data item name.
#**

use strict;
use warnings;

use COD::CIF::Tags::Print qw( print_single_tag_and_value );

my $data_name = '_test_data_name';
my $value = ';value-that-starts-with-a-semicolon-and-has-no-spaces-(i.e.-an-InChi-string);';
my $fold_long_fields = 0;
my $folding_width = 80;
my $cif_version = 1.1;

print_single_tag_and_value(
    '_pre_data_name',
    'value_1',
    $fold_long_fields,
    $folding_width,
    $cif_version
);

print_single_tag_and_value(
    $data_name,
    $value,
    $fold_long_fields,
    $folding_width,
    $cif_version
);

print_single_tag_and_value(
    '_post_data_name',
    'value_2',
    $fold_long_fields,
    $folding_width,
    $cif_version
);

END_SCRIPT
