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
    'name'   => 'several_enantiomer_data_names',
    'tags'   => [
                  '_cod_related_enantiomer_entry.id',
                  '_cod_related_enantiomer_entry.code',
                  '_cod_related_enantiomer_entry_id',
                  '_cod_related_enantiomer_entry_code',
                  '_cod_enantiomer_of'
                ],
    'loops'  => [
                  [
                    '_cod_related_enantiomer_entry.id',
                    '_cod_related_enantiomer_entry.code'
                  ],
                                    [
                    '_cod_related_enantiomer_entry_id',
                    '_cod_related_enantiomer_entry_code'
                  ],
                  [
                    '_cod_enantiomer_of'
                  ],
                ],
    'inloop' => {
                  '_cod_related_enantiomer_entry.id' => 0,
                  '_cod_related_enantiomer_entry.code' => 0,
                  '_cod_related_enantiomer_entry_id' => 1,
                  '_cod_related_enantiomer_entry_code' => 1,
                  '_cod_enantiomer_of' => 2
                },
    'values' => {
                  '_cod_related_enantiomer_entry.id' => [
                    '1', '2', '3', '4'
                  ],
                  '_cod_related_enantiomer_entry.code' => [
                    '0000001', '0000002', '0000004', '0000003'
                  ],
                  '_cod_related_enantiomer_entry_id' => [
                    '1', '2', '3', '4'
                  ],
                  '_cod_related_enantiomer_entry_code' => [
                    '0000004', '0000005', '0000006', '0000007'
                  ],
                  '_cod_enantiomer_of' => [
                    '0000009', '0000004', '0000006', '0000006'
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
