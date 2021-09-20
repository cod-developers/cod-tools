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
#* subroutine. Tests the way CIF 1.1 data item values that contain various
#* CIF 1.1 and CIF 2.0 delimiter symbols are handled. In this case, the
#* delimiter symbols appear only in the middle of an uninterupted text
#* string and thus the value does not require any additional surrounding
#* delimiters.
#**

use strict;
use warnings;

use COD::CIF::Tags::Print qw( print_single_tag_and_value );

my $fold_long_fields = 0;
my $folding_width = 80;
my $cif_version = '1';

my @feature_sets;
for my $i (0..15) {
    my $binary = sprintf "%04b", $i;
    push @feature_sets, [ split '', $binary ];
}

my $count = 0;
for my $feature (@feature_sets) {
    $count++;
    my $value = 'start';
    $value .= "-'"   if $feature->[3];
    $value .= '-"'   if $feature->[2];
    $value .= "-'''" if $feature->[1];
    $value .= '-"""' if $feature->[0];
    $value .= '-end';

    print "# sq:  $feature->[3]\n";
    print "# dq:  $feature->[2]\n";
    print "# tsq: $feature->[1]\n";
    print "# tdq: $feature->[0]\n";

    print_single_tag_and_value(
        "_pre_test_item_$count",
        "pre_value_$count",
        $fold_long_fields,
        $folding_width,
        $cif_version
    );

    print_single_tag_and_value(
        "_test_item_$count",
        $value,
        $fold_long_fields,
        $folding_width,
        $cif_version
    );

    print_single_tag_and_value(
        "_post_test_item_$count",
        "post_value_$count",
        $fold_long_fields,
        $folding_width,
        $cif_version
    );
}

END_SCRIPT
