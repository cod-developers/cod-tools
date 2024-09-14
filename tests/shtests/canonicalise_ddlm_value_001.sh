#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/DDL/DDLm.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( canonicalise_ddlm_value )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::DDL::DDLm::canonicalise_ddlm_value subroutine.
#* Tests the way the subroutine behaves when the input value is a special
#* type of number (inf, NaN).
#**

use strict;
use warnings;

# use COD::CIF::DDL::DDLm qw( canonicalise_ddlm_value );

my @sanity_values = (
    42,
    42.000,
    42.000,
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
    '-naN'
);

print "Sanity values:\n";
for my $value (@sanity_values) {
    print canonicalise_ddlm_value( $value, 'integer'), "\n";
}

print "Test values:\n";
for my $value (@test_values) {
    print canonicalise_ddlm_value( $value, 'integer'), "\n";
}

END_SCRIPT
