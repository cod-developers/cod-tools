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
#* Unit test for the COD::CIF::Data::CODFlags::has_error_flag_value subroutine.
#* Tests the way the subroutine behaves when the input data block does not
#* contain flags of the requested severity.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags;

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

if (COD::CIF::Data::CODFlags::has_error_flag_value($data_block, 'warnings')) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains the \'warnings\' error flag.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain the \'warnings\' error flag.' . "\n";
}

END_SCRIPT
