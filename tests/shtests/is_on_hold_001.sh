#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODFlags.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( is_on_hold )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::is_on_hold subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* various data items that indicate that the entry is on hold as a
#* predeposition entry.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODFlags qw( is_on_hold );

my $data_block_1 =
{
  'name'   => 'on_hold_item_1',
  'tags'   => [ '_cod_depositor.requested_release_date' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_depositor.requested_release_date' => [ '1970-01-01' ] },
  'precisions' => {},
  'types'  => { '_cod_depositor.requested_release_date' => [ 'UQSTRING' ] },
};

my $data_block_2 =
{
  'name'   => 'on_hold_item_2',
  'tags'   => [ '_cod_depositor_requested_release_date' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_depositor_requested_release_date' => [ '1970-01-01' ] },
  'precisions' => {},
  'types'  => { '_cod_depositor_requested_release_date' => [ 'UQSTRING' ] },
};

my $data_block_3 =
{
  'name'   => 'on_hold_item_3',
  'tags'   => [ '_cod_hold_until_date' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_hold_until_date' => [ '1970-01-01' ] },
  'precisions' => {},
  'types'  => { '_cod_hold_until_date' => [ 'UQSTRING' ] },
};

my $data_block_4 =
{
  'name'   => 'on_hold_item_4',
  'tags'   => [ '_[local]_cod_hold_until_date' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_[local]_cod_hold_until_date' => [ '1970-01-01' ] },
  'precisions' => {},
  'types'  => { '_[local]_cod_hold_until_date' => [ 'UQSTRING' ] },
};

my @blocks = (
    $data_block_1,
    $data_block_2,
    $data_block_3,
    $data_block_4,
);

for my $data_block ( @blocks ) {
    my $is_on_hold = is_on_hold( $data_block );
    if ( $is_on_hold ) {
        print 'Data block \'' . $data_block->{'name'} . '\' is marked as being on hold.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' is not marked as being on hold.' . "\n";
    }
}

END_SCRIPT
