#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/CODFlags.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::is_duplicate subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* various data items that indicate that the entry is a duplicate one.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_duplicate );

my $data_block_1 =
{
  'name'   => 'duplicate_item_1',
  'tags'   => [ '_cod_related_duplicate_entry.code' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_related_duplicate_entry.code' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_cod_related_duplicate_entry.code' => [ 'UQSTRING' ]},
};

my $data_block_2 =
{
  'name'   => 'duplicate_item_2',
  'tags'   => [ '_cod_related_duplicate_entry_code' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_related_duplicate_entry_code' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_cod_related_duplicate_entry_code' => [ 'UQSTRING' ]},
};

my $data_block_3 =
{
  'name'   => 'duplicate_item_3',
  'tags'   => [ '_cod_duplicate_entry' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_duplicate_entry' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_cod_duplicate_entry' => [ 'UQSTRING' ]},
};

my $data_block_4 =
{
  'name'   => 'duplicate_item_4',
  'tags'   => [ '_[local]_cod_duplicate_entry' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_[local]_cod_duplicate_entry' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_[local]_cod_duplicate_entry' => [ 'UQSTRING' ]},
};

my @blocks = (
    $data_block_1,
    $data_block_2,
    $data_block_3,
    $data_block_4
);

for my $data_block ( @blocks ) {
    my $is_suboptimal = is_duplicate( $data_block );
    if ( $is_suboptimal ) {
        print 'Data block \'' . $data_block->{'name'} . '\' is marked as a duplicate entry.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' is not marked as a duplicate entry.' . "\n";
    }
}

END_SCRIPT
