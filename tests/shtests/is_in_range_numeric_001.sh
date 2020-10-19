#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/DDL/Ranges.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::DDL::Ranges::is_in_range_numeric subroutine.
#* Tests the way the subroutine behaves when the input value is a special
#* type of number (inf, NaN);
#**

use strict;
use warnings;

use COD::CIF::DDL::Ranges;

my $range = [ -50, undef ];

my @sanity_values = (
    42,
    -420.000,
    420.000,
);

my @test_values = (
    'test',
    'inf',
    '+inf',
    '-inf',
    'infinity',
    '+infiNity',
    '-infinity',
    'NaN',
    '+nan',
    '-naN',
);

print "Sanity values:\n";
for my $value (@sanity_values) {
    print $value, ': ';
    if ( COD::CIF::DDL::Ranges::is_in_range_numeric( $value, { 'range' => $range } ) ) {
        print 'in range';
    } else {
        print 'not in range';
    }
    print "\n";
}

print "Test values:\n";
for my $value (@test_values) {
    print $value, ': ';
    if ( COD::CIF::DDL::Ranges::is_in_range_numeric( $value, { 'range' => $range } ) ) {
        print 'in range';
    } else {
        print 'not in range';
    }
    print "\n";
}

END_SCRIPT
