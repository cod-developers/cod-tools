#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/DDL/DDLm.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::DDL::DDLm::canonicalise_ddlm_complex_value()
#* subroutine. Tests the way incorrectly formatted complex values are handled.
#* Values that cannot be successfully parsed should be returned unchanged.
#**

use strict;
use warnings;

use COD::CIF::DDL::DDLm;

my @test_values = (
    '10',
    '7j',
    '100(5) - -1j',
    '100 + 5.0(0.5)j',
);

for my $value (@test_values) {
    print "'$value'";
    print ' -> ';
    print "'", COD::CIF::DDL::DDLm::canonicalise_ddlm_complex_value($value), "'";
    print "\n";
}

END_SCRIPT
