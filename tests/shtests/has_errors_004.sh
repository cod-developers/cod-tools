#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODFlags.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( has_errors )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::has_errors subroutine.
#* Tests the way the subroutine behaves when the input data block does
#* not contain any of the data items that would mark it as containing
#* errors.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODFlags qw( has_errors );

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

if (has_errors($data_block)) {
    print 'Data block \'' . $data_block->{'name'} . '\' contains errors.' . "\n";
} else {
    print 'Data block \'' . $data_block->{'name'} . '\' does not contain errors.' . "\n";
}


END_SCRIPT
