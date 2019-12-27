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
#* no data items that mark it as a duplicate structure.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_duplicate );

my $data_block_1 =
{
  'name'   => 'neutral_item',
  'tags'   => [ '_neutral_item' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_neutral_item' => [ 'yes' ] },
  'precisions' => {},
  'types'  => { '_neutral_item' => [ 'UQSTRING' ] },
};

my @blocks = (
    $data_block_1,
);

for my $data_block ( @blocks ) {
    my $is_duplicate = is_duplicate( $data_block );
    if ( $is_duplicate ) {
        print 'Data block \'' . $data_block->{'name'} . '\' is marked as a duplicate entry.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' is not marked as a duplicate entry.' . "\n";
    }
}

END_SCRIPT
