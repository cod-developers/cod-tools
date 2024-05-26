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
#* Unit test for the COD::CIF::Data::CODNumbers::timestamps_are_the_same()
#* subroutine. Tests the way the subroutine handles situations when the values
#* are different and expressed as date only timestamps.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODNumbers;

my $value_1 = '2017-01-02';
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

END_SCRIPT
