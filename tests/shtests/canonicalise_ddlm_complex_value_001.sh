#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/DDL/DDLm.pm
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
#* Unit test for the COD::CIF::DDL::DDLm::canonicalise_ddlm_complex_value()
#* subroutine. Tests the way correctly formatted complex values are handled.
#**

use strict;
use warnings;

# use COD::CIF::DDL::DDLm;

my @test_values = (
    '10+7j',
    '10 + 7j',
    '100(5) - 1.7j',
    '10.0 - 5(1)j',
    '10.15(1)+300.0(100)j'
);

for my $value (@test_values) {
    print "'$value'";
    print ' -> ';
    print "'", COD::CIF::DDL::DDLm::canonicalise_ddlm_complex_value($value), "'";
    print "\n";
}

END_SCRIPT
