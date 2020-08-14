#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_PRINT='src/lib/perl5/COD/Formulae/Print.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Unit test for the COD::Formulae::Print::print_formula() subroutine.
#**

use strict;
use warnings;

use COD::Formulae::Print qw( print_formula );

print_formula( { C  => 1.000000000000001 }, '%s' );
print_formula( { C  => 1 }, '%s' );
print_formula( { C  => 0 }, '%s' );
print_formula( { H  => 0 }, '%s' );
print_formula( { Cl => 0 }, '%s' );

END_SCRIPT
