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
#* Unit test for the COD::CIF::DDL::DDLm::canonicalise_ddlm_imag_value()
#* subroutine. Tests the way incorrectly formatted imag values are handled.
#* Values that cannot be successfully parsed should be returned unchanged.
#**

use strict;
use warnings;

use COD::CIF::DDL::DDLm;

my @test_values = (
    '10jj',
    '7',
    '-1j ',
    '5.0(0.5)j',
);

for my $value (@test_values) {
    print "'$value'";
    print ' -> ';
    print "'", COD::CIF::DDL::DDLm::canonicalise_ddlm_imag_value($value), "'";
    print "\n";
}

END_SCRIPT
