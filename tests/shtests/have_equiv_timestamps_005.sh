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
#* subroutine. Tests the way the subroutine handles situations when both values
#* have the same date, but one value also contains the time. Values should
#* be treated as being identical.
#**

use strict;
use warnings;

use COD::CIF::Data::CODNumbers;

my $value_1 = '2017-01-01';
my $value_2 = '2017-01-01T01:01:01.01Z';

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
