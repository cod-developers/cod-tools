#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/CIF2COD.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CIF2COD::get_cod_status_from_issue_severity
#* subroutine. Tests the way the subroutine behaves when the input data block
#* does not contain the '_cod_entry_issue_severity' data item.
#**

use strict;
use warnings;

use COD::CIF::Data::CIF2COD;

my $data_block =
{
  'name'   => 'neutral_item',
  'tags'   => [ '_neutral_item' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_neutral_item' => [ 'yes' ] },
  'precisions' => {},
  'types'  => { '_neutral_item' => [ 'UQSTRING' ] },
};

my $value = COD::CIF::Data::CIF2COD::get_cod_status_from_issue_severity($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status.' . "\n";
}

END_SCRIPT
