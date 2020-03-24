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
#* Unit test for the COD::CIF::Data::CODFlags::is_retracted subroutine.
#* Tests the way the subroutine behaves when the input data block does
#* not contain any of the data items that would mark it as being retracted.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_retracted );

my $data_block =
{
  'name'   => 'neutral_item',
  'tags'   => [ '_neutral_item' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_neutral_item' => [ 'yes' ] },
  'precisions' => {},
  'types'  => { '_neutral_item' => [ 'UQSTRING' ] },
};

if (is_retracted($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' is marked as retracted.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' is not marked as retracted.' . "\n";
}


END_SCRIPT
