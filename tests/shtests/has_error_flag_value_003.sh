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
    'name'   => 'cod_error_flag_warning',
    'tags'   => [ '_cod_error_flag' ],
    'loops'  => [],
    'inloop' => {},
    'values' => { '_cod_error_flag' => [ 'warnings' ] },
    'precisions' => {},
    'types' => { '_cod_error_flag' => [ 'UQSTRING' ] },
};

if (COD::CIF::Data::CODFlags::has_error_flag_value($data_block, 'new_flag_value')) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains the \'new_flag_value\' error flag.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain the \'new_flag_value\' error flag.' . "\n";
}

END_SCRIPT
