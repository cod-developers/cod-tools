#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/MarkDisorder.pm'
#END DEPEND--------------------------------------------------------------------
#**
#* Unit test for the COD::CIF::Data::MarkDisorder::generate_additional_assembly_names()
#* subroutine. Tests the way multiple additional assembly codes are generated
#* based on the existing ones. 
#**

perl <<'END_SCRIPT'

use strict;
use warnings;

use COD::CIF::Data::MarkDisorder;

sub test_subroutine
{
    return &COD::CIF::Data::MarkDisorder::generate_additional_assembly_names(@_);    
}

my $assembly_count;

my @cases = map { [ $_ ] } qw( . A Z ID-001 TEST-NAME _ _0 );
unshift @cases, [];
# Sequential numeric values with an different number of digits.
push @cases, [ 9, 10 ];
push @cases, [ 'A', 'B', 'C' ];
push @cases, [ 'AA', 'Z' ];
push @cases, [ 'ZB', 'ZA', 'ZZ' ];
push @cases, [ 'DE', 'ABC', 'Z' ];
push @cases, [  '.', 'A' ];
push @cases, [  '.', '+' ];

$assembly_count = 1;
print "# Additional disorder assembly count: $assembly_count\n";
for (@cases) {
    print '[ ' . join( ', ', map { "'$_'" } @$_ ) . ' ] -> \'' .
          join( "', '", test_subroutine( $_, $assembly_count ) ) . "'\n";
}

$assembly_count = 2;
print "# Additional disorder assembly count: $assembly_count\n";
for (@cases) {
    print '[ ' . join( ', ', map { "'$_'" } @$_ ) . ' ] -> \'' .
          join( "', '", test_subroutine( $_, $assembly_count ) ) . "'\n";
}

$assembly_count = 3;
print "# Additional disorder assembly count: $assembly_count\n";
for (@cases) {
    print '[ ' . join( ', ', map { "'$_'" } @$_ ) . ' ] -> \'' .
          join( "', '", test_subroutine( $_, $assembly_count ) ) . "'\n";
}

$assembly_count = 10;
print "# Additional disorder assembly count: $assembly_count\n";
for (@cases) {
    print '[ ' . join( ', ', map { "'$_'" } @$_ ) . ' ] -> \'' .
          join( "', '", test_subroutine( $_, $assembly_count ) ) . "'\n";
}

END_SCRIPT
