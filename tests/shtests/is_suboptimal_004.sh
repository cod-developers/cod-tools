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
#* Unit test for the COD::CIF::Data::CODFlags::is_suboptimal subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* a data item that references an optimal data structure.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_suboptimal );

my $data_block_1 =
{
  'name'   => 'suboptimal_1',
  'tags'   => [ '_cod_related_optimal_entry.code' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_related_optimal_entry.code' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_cod_related_optimal_entry.code' => [ 'UQSTRING' ]},
};

my $data_block_2 =
{
  'name'   => 'suboptimal_2',
  'tags'   => [ '_cod_related_optimal_entry_code' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_related_optimal_entry_code' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_cod_related_optimal_entry_code' => [ 'UQSTRING' ]},
};

my $data_block_3 =
{
  'name'   => 'suboptimal_3',
  'tags'   => [ '_cod_related_optimal_struct' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_related_optimal_struct' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_cod_related_optimal_struct' => [ 'UQSTRING' ]},
};

my $data_block_4 =
{
  'name'   => 'suboptimal_4',
  'tags'   => [ '_[local]_cod_related_optimal_struct' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_[local]_cod_related_optimal_struct' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_[local]_cod_related_optimal_struct' => [ 'UQSTRING' ]},
};

my @blocks = (
    $data_block_1,
    $data_block_2,
    $data_block_3,
    $data_block_4,
);

for my $data_block ( @blocks ) {
    my $is_suboptimal = is_suboptimal( $data_block );
    if ( $is_suboptimal ) {
        print 'Data block \'' . $data_block->{'name'} . '\' is marked as suboptimal.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' is not marked as suboptimal.' . "\n";
    }
}

END_SCRIPT
