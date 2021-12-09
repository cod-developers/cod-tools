#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/MarkDisorder.pm
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'

use strict;
use warnings;
use COD::CIF::Data::MarkDisorder;
use Data::Dumper;

my @cases = map { [ $_ ] } qw( A Z ID-001 TEST-NAME _ _0 );
unshift @cases, [];
push @cases, [ 9, 10 ];

for (@cases) {
    print Dumper
        [ COD::CIF::Data::MarkDisorder::get_new_assembly_names( $_ ) ];
}

END_SCRIPT
