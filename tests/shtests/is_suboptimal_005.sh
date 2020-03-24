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
#* both the '_cod_suboptimal_structure' data item and a data item that
#* references an optimal data structure.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_suboptimal );

my $data_block_1 =
{
  'name'   => 'explicitly_suboptimal',
  'tags'   => [ '_cod_suboptimal_structure',
                '_cod_related_optimal_entry.code' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_suboptimal_structure' => [ 'yes' ],
                '_cod_related_optimal_entry.code' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_cod_suboptimal_structure' => [ 'UQSTRING' ],
                '_cod_related_optimal_entry.code' => [ 'UQSTRING' ] },
};

my $data_block_2 =
{
  'name'   => 'explicitly_not_suboptimal',
  'tags'   => [ '_cod_suboptimal_structure',
                '_cod_related_optimal_entry_code' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_suboptimal_structure' => [ 'no' ],
                '_cod_related_optimal_entry_code' => [ '0000000' ] },
  'precisions' => {},
  'types'  => { '_cod_suboptimal_structure' => [ 'UQSTRING' ],
                '_cod_related_optimal_entry_code' => [ 'UQSTRING' ] },
};

my @blocks = (
    $data_block_1,
    $data_block_2,
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
