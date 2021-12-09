#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/MarkDisorder.pm
#END DEPEND--------------------------------------------------------------------
#**
#* Unit test for the COD::CIF::Data::MarkDisorder::get_new_assembly_names()
#* subroutine. Tests the way sequential numeric values with an different number
#* of digits are handled.
#*
#* FIXME: the subroutine returns a values that matches one of the values that
#* are already in use (from @seen_assemblies).
#**

perl <<'END_SCRIPT'

use strict;
use warnings;
use COD::CIF::Data::MarkDisorder;

my @seen_assemblies = ( 9, 10 );
my @new_assemblies = COD::CIF::Data::MarkDisorder::get_new_assembly_names(
                         \@seen_assemblies,
                         1
                     );

print "Existing assemblies:\n", ( join "\n", @seen_assemblies );
print "\n";
print "New assemblies:\n", ( join "\n", @new_assemblies );
print "\n";

END_SCRIPT
