#!/bin/sh

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
#* Unit test for the COD::CIF::Data::CODNumbers::get_related_enantiomer_entry_codes()
#* subroutine. Tests the way the subroutine behaves when the input data block
#* contains the '_cod_enantiomer_of' data item.
#**

use strict;
use warnings;

use COD::CIF::Data::CODNumbers;

my $data_block =
{
    'name'   => 'cod_enantiomer_of',
    'tags'   => [
                  '_cod_enantiomer_of'
                ],
    'loops'  => [
                  [
                    '_cod_enantiomer_of'
                  ],
                ],
    'inloop' => {
                  '_cod_enantiomer_of' => 0
                },
    'values' => {
                  '_cod_enantiomer_of' => [
                    '0000001', '0000002', '0000004', '0000003'
                  ],
                },
    'precisions' => {},
    'types'  => {
                  '_cod_enantiomer_of' => [
                    'UQSTRING', 'UQSTRING', 'UQSTRING', 'UQSTRING'
                  ]
                },
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
