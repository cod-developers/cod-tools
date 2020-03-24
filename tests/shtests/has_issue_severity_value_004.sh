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
#* Unit test for the COD::CIF::Data::CODFlags::has_issue_severity_value
#* subroutine. Tests the way the subroutine behaves when the input data
#* block does not contain issues of the requested severity.
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

if (COD::CIF::Data::CODFlags::has_issue_severity_value($data_block, 'warning')) {
    print "At least one issue of the 'warning' severity was located.\n";
} else {
    print "No issues of the 'warning' severity were located.\n";
}

END_SCRIPT
