#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/Formulae/Print.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( print_formula )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Unit test for the COD::Formulae::Print::print_formula() subroutine.
#  Tests the way elements with the atom count of '0' are represented
#  in the formula.
#**

use strict;
use warnings;

use COD::Formulae::Print qw( print_formula );

print_formula( { C  => 0.0 }, '%g' );
print_formula( { C  => 0 }, '%g' );
print_formula( { H  => 0 }, '%g' );
print_formula( { Cl => 0 }, '%g' );

END_SCRIPT
