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
#* subroutine. Tests the way correctly formatted imag values are handled.
#**

use strict;
use warnings;

use COD::CIF::DDL::DDLm;

my @test_values = (
    '7j',
    '+7j',
    '-1j',
    '-5(3)j',
    '300.0(100)j'
);

for my $value (@test_values) {
    print "'$value'";
    print ' -> ';
    print "'", COD::CIF::DDL::DDLm::canonicalise_ddlm_imag_value($value), "'";
    print "\n";
}

END_SCRIPT
