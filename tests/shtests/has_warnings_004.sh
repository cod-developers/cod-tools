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
#* Unit test for the COD::CIF::Data::CODFlags::has_warnings subroutine.
#* Tests the way the subroutine behaves when the input data block does
#* not contain any of the data items that would mark it as containing
#* warnings.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_warnings );

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

if (has_warnings($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains warnings.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain warnings.' . "\n";
}


END_SCRIPT
