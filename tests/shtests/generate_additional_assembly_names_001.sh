#!/bin/sh
#**
#* Unit test for the COD::CIF::Data::MarkDisorder::generate_additional_assembly_names()
#* subroutine. Tests the way additional assembly codes are generated based on
#* the existing ones. 
#**

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/MarkDisorder.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE}" \
<<'END_SCRIPT'

use strict;
use warnings;

# use COD::CIF::Data::MarkDisorder;

my @cases = map { [ $_ ] } qw( . A Z ID-001 TEST-NAME _ _0 );
unshift @cases, [];
# Sequential numeric values with an different number of digits.
push @cases, [ 9, 10 ];
push @cases, [ 'AA', 'Z' ];
push @cases, [  '.', 'A' ];
push @cases, [  '.', '+' ];

for (@cases) {
    print '[ ' . join( ', ', map { "'$_'" } @$_ ) . ' ] -> \'' .
          join( "', '", COD::CIF::Data::MarkDisorder::generate_additional_assembly_names( $_ ) ) . "'\n";
}

END_SCRIPT
