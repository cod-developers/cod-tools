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
#* Tests the way the subroutine behaves when the input data block contains
#* the '_cod_error_flag' data item with the 'warnings' flag value.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_warnings );

my $data_block =
{
    'name'   => 'cod_warnings_error_flag',
    'tags'   => [ '_cod_error_flag' ],
    'loops'  => [],
    'inloop' => {},
    'values' => { '_cod_error_flag' => [ 'warnings' ] },
    'precisions' => {},
    'types' => { '_cod_error_flag' => [ 'UQSTRING' ] },
};

if (has_warnings($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains warnings.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain warnings.' . "\n";
}

END_SCRIPT
