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
#* subroutine. Tests the way CIF 2.0 data item values that are near the
#* max line length limit of 80 symbols are handled.
#**

use strict;
use warnings;

use COD::CIF::Tags::Print qw( print_single_tag_and_value );

my $fold_long_fields = 0;
my $folding_width = 80;
my $cif_version = '2';

my $value_with_spaces    = 'Long value with white space symbols ++++++++';
my $value_without_spaces = '$Long-value-with-no-white-space-symbols-++++';

print "# Total line length: 79\n";
print_single_tag_and_value(
    "_test_case_1_a",
    $value_with_spaces,
    $fold_long_fields,
    $folding_width,
    $cif_version
);

print_single_tag_and_value(
    "_test_case_1_b",
    $value_without_spaces,
    $fold_long_fields,
    $folding_width,
    $cif_version
);

print "\n";

print "# Total line length: 80\n";
print_single_tag_and_value(
    "_test_case_2_a",
    "$value_with_spaces+",
    $fold_long_fields,
    $folding_width,
    $cif_version
);

print_single_tag_and_value(
    "_test_case_2_b",
    "$value_without_spaces+",
    $fold_long_fields,
    $folding_width,
    $cif_version
);

print "\n";

print "# Total line length: 81\n";
print_single_tag_and_value(
    "_test_case_2_a",
    "$value_with_spaces++",
    $fold_long_fields,
    $folding_width,
    $cif_version
);

print_single_tag_and_value(
    "_test_case_2_b",
    "$value_without_spaces++",
    $fold_long_fields,
    $folding_width,
    $cif_version
);

print "\n";

END_SCRIPT
