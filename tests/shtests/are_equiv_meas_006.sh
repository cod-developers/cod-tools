#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/CODNumbers.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODNumbers::are_equiv_meas() subroutine.
#* Tests the way the subroutine behaves when two number with s.u. values are
#* compared, but none of the s.u. values are provided.
#**

use strict;
use warnings;

use COD::CIF::Data::CODNumbers;

my $value_1 = 4;
my $value_2 = 3;

my $equivalent = COD::CIF::Data::CODNumbers::are_equiv_meas(
    $value_1,
    $value_2,
    {
    }
);

if ( $equivalent ) {
    print "Values '$value_1' and '$value_2' were treated as equivalent.\n";
} else {
    print "Values '$value_1' and '$value_2' were treated as not equivalent.\n";
}

END_SCRIPT
