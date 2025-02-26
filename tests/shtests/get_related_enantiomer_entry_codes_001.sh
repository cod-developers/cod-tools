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
#* Unit test for the COD::CIF::Data::CODNumbers::get_related_enantiomer_entry_codes()
#* subroutine. Tests the way the subroutine behaves when the input data block
#* contains none of the relevant data items.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODNumbers;

my $data_block =
{
    'name'   => 'no_related_enantiomers',
    'tags'   => [],
    'loops'  => [],
    'inloop' => {},
    'values' => {},
    'precisions' => {},
    'types'  => {},
};

my $related_enantiomer_entries =
    COD::CIF::Data::CODNumbers::get_related_enantiomer_entry_codes($data_block);

if (@{$related_enantiomer_entries}) {
    print "Data block '$data_block->{'name'}' contains references to the " .
          'following related enantiomer entries:' . "\n" .
          ( join "\n", @{$related_enantiomer_entries}) . "\n";
} else {
    print "Data block '$data_block->{'name'}' contains no references to " .
          'related enantiomer entries.' . "\n";
}

END_SCRIPT
