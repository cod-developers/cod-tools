#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODNumbers.pm
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
#* Unit test for the COD::CIF::Data::CODNumbers::are_equiv_meas() subroutine.
#* Tests the way the subroutine behaves when two number with s.u. values are
#* compared and the 'use_su' option is disabled.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODNumbers;

my $value_1 = 4;
my $value_2 = 3;
my $su_1    = 3;
my $su_2    = 1;
my $use_su  = 0;

my $equivalent = COD::CIF::Data::CODNumbers::are_equiv_meas(
    $value_1,
    $value_2,
    {
        'use_su' => $use_su,
        'su_1'   => $su_1,
        'su_2'   => $su_2,
    }
);

if ( $equivalent ) {
    print "Values '$value_1' and '$value_2' were treated as equivalent.\n";
} else {
    print "Values '$value_1' and '$value_2' were treated as not equivalent.\n";
}

END_SCRIPT
