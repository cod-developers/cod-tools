#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODFlags.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( has_warnings )" \
<<'END_SCRIPT'
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
