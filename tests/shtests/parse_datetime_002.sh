#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/Check.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::Check::parse_datetime() subroutine.
#* Tests how various timestamp strings that do not correspond to the
#* required format are handled.
#**

use strict;
use warnings;

use COD::CIF::Data::Check;

my @datetime_values = (
    # Overall incorrect date format
    'This is a text string',
    # Month lies outside the [1, 12] range
    '2000-23-01',
    # Day lies outside the allowed range for the given month
    '2000-02-30',
    # Incorrect datetime
    '1985-04-12T23:20:50.52J',
    # Space instead of the 'T' separator
    '1985-04-12 23:20:50.52Z',
    # Lower case letters
);

for (@datetime_values) {
    eval {
        my $dt = COD::CIF::Data::Check::parse_datetime($_);
        print $dt->datetime . "\n";
    };
    if ($@) {
        print "Value '$_' could not be succesfully parsed as a timestamp value.\n";
    }
}

END_SCRIPT
