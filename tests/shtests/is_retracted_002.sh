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
#* Tests the way the subroutine behaves when the input data block contains
#* the '_cod_error_flag' data item with the 'retracted' flag value.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_retracted );

my $data_block =
{
    'name'   => 'cod_retracted_error_flag',
    'tags'   => [ '_cod_error_flag' ],
    'loops'  => [],
    'inloop' => {},
    'values' => { '_cod_error_flag' => [ 'retracted' ] },
    'precisions' => {},
    'types' => { '_cod_error_flag' => [ 'UQSTRING' ] },
};

if (is_retracted($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' is marked as retracted.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' is not marked as retracted.' . "\n";
}

END_SCRIPT
