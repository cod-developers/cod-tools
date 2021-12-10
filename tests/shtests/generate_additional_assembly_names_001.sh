#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/MarkDisorder.pm
#END DEPEND--------------------------------------------------------------------
#**
#* Unit test for the COD::CIF::Data::MarkDisorder::generate_additional_assembly_names()
#* subroutine. Tests the way sequential numeric values with an different number
#* of digits are handled.
#**

perl <<'END_SCRIPT'

use strict;
use warnings;
use COD::CIF::Data::MarkDisorder;
use Data::Dumper;

my @cases = map { [ $_ ] } qw( . A Z ID-001 TEST-NAME _ _0 );
unshift @cases, [];
push @cases, [ 9, 10 ];
push @cases, [ 'AA', 'Z' ];
push @cases, [  '.', 'A' ];
push @cases, [  '.', '+' ];

for (@cases) {
    print '[ ' . join( ', ', map { "'$_'" } @$_ ) . ' ] -> \'' .
          join( "', '", COD::CIF::Data::MarkDisorder::generate_additional_assembly_names( $_ ) ) . "'\n";
}

END_SCRIPT
