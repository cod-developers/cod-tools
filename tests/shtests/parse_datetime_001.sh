#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/Check.pm
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
#* Unit test for the COD::CIF::Data::Check::parse_datetime() subroutine.
#* Tests how various timestamp strings that correspond to the required
#* format are handled.
#**

use strict;
use warnings;

use COD::CIF::Data::Check;

my @datetime_values = (
    # Date-only timestamp
    '2000-01-01',
    # Examples from RFC 3339
    '1985-04-12T23:20:50.52Z',
    '1990-12-31T23:59:60Z',
    '1990-12-31T15:59:60-08:00',
    '1937-01-01T12:00:27.87+00:20',
    # Lower case letters
    '1985-04-12t23:20:50.52z',
);

for (@datetime_values) {
    my $dt = COD::CIF::Data::Check::parse_datetime($_);
    print $dt->datetime . "\n";
}

END_SCRIPT
