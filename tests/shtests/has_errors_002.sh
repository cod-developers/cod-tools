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
#* Unit test for the COD::CIF::Data::CODFlags::has_errors subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* the '_cod_error_flag' data item with the 'errors' flag value.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_errors );

my $data_block =
{
    'name'   => 'cod_errors_error_flag',
    'tags'   => [ '_cod_error_flag' ],
    'loops'  => [],
    'inloop' => {},
    'values' => { '_cod_error_flag' => [ 'errors' ] },
    'precisions' => {},
    'types' => { '_cod_error_flag' => [ 'UQSTRING' ] },
};

if (has_errors($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains errors.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain errors.' . "\n";
}

END_SCRIPT
