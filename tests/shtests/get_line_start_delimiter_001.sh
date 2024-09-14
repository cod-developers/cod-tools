#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Tags/Print.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE}" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Print::get_line_start_delimiter()
#* subroutine. Tests the way the subroutine escapes CIF 1.1 values that
#* contain various CIF 1.1 and CIF 2.0 delimiters, but are not prefixed
#* with a semicolon. 
#**

use strict;
use warnings;

# use COD::CIF::Tags::Print;

my $cif_version = '1';

my @feature_sets;
for my $i (0..15) {
    my $binary = sprintf "%04b", $i;
    push @feature_sets, [ split '', $binary ];
}

for my $feature (@feature_sets) {
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
    my $q = COD::CIF::Tags::Print::get_line_start_delimiter($value, $cif_version);
    if ($q eq ';') {
        print $q . $value . "\n" . $q . "\n";
    } else {
        print $q . $value . $q . "\n";
    }
}

END_SCRIPT
