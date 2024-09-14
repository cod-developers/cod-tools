#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CIF2COD.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE}" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CIF2COD::get_cod_status_from_error_flag
#* subroutine. Tests the way the subroutine behaves when the input data block
#* contains no data items that mark the structurure as having errors.
#**

use strict;
use warnings;

# use COD::CIF::Data::CIF2COD;

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

my $value = COD::CIF::Data::CIF2COD::get_cod_status_from_error_flag($data_block);
if (defined $value) {
    print 'Data block \'' . $data_block->{'name'} . "' has the '$value' status." . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' has an undefined status.' . "\n";
}

END_SCRIPT
