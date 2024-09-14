#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE}" \
<<'END_SCRIPT'
#**
#* Unit test for the COD::CIF::Data::lookup_space_group() subroutine.
#* Tests the lookup using the 'hall' space group property.
#**

use strict;
use warnings;

# use COD::CIF::Data;

my @space_group_values = (
    'R 3',
    ' R 3',
    ' R 3 ',
    ' R  3 ',
    'R 3  ',
    '__R__3 __ '
);

for my $value (@{space_group_values}) {
    my $space_group = COD::CIF::Data::lookup_space_group('hall', $value);
    if (defined $space_group) {
        print "'" . $value . "'", ' -> ', "'" . $space_group->{'hall'} . "'", "\n";
    } else {
        print "'" . $value . "'", ' -> ', 'undef', "\n";
    }
}

END_SCRIPT
