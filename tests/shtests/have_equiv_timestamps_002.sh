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
#* Unit test for the COD::CIF::Data::CODNumbers::timestamps_are_the_same()
#* subroutine. Tests the way the subroutine handles situations when one of
#* the timestamp values is undefined.
#**

use strict;
use warnings;

use COD::CIF::Data::CODNumbers;

my $value_1 = undef;
my $value_2 = '2017-01-01';

my $data_name = '_raman_measurement.datetime_initiated';
my $entry_1 = {
    'timestamp' => {
        $data_name => $value_1,
    }
};

my $entry_2 = {
    'timestamp' => {
        $data_name => $value_2,
    }
};

if ( COD::CIF::Data::CODNumbers::have_equiv_timestamps($entry_1, $entry_2, $data_name) ) {
    print "Values are treated as being the same.\n";
} else {
    print "Values are treated as being different.\n";
}

if ( COD::CIF::Data::CODNumbers::have_equiv_timestamps($entry_2, $entry_1, $data_name) ) {
    print "Values are treated as being the same.\n";
} else {
    print "Values are treated as being different.\n";
}

END_SCRIPT
