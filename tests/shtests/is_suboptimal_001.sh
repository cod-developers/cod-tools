#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODFlags.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( is_suboptimal )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::is_suboptimal subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* the '_cod_suboptimal_structure' data item with various values.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODFlags qw( is_suboptimal );

my $data_block_1 =
{
  'name'   => 'suboptimal',
  'tags'   => [ '_cod_suboptimal_structure' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_suboptimal_structure' => [ 'yes' ] },
  'precisions' => {},
  'types'  => { '_cod_suboptimal_structure' => [ 'UQSTRING' ]},
};

my $data_block_2 =
{
  'name'   => 'not_suboptimal',
  'tags'   => [ '_cod_suboptimal_structure' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_suboptimal_structure' => [ 'no' ] },
  'precisions' => {},
  'types'  => { '_cod_suboptimal_structure' => [ 'UQSTRING' ]},
};

my $data_block_3 =
{
  'name'   => 'invalid',
  'tags'   => [ '_cod_suboptimal_structure' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_cod_suboptimal_structure' => [ 'faulty' ] },
  'precisions' => {},
  'types'  => { '_cod_suboptimal_structure' => [ 'UQSTRING' ]},
};

my @blocks = (
    $data_block_1,
    $data_block_2,
    $data_block_3,
);

for my $data_block ( @blocks ) {
    my $is_suboptimal = is_suboptimal( $data_block );
    if ( $is_suboptimal ) {
        print 'Data block \'' . $data_block->{'name'} . '\' is marked as suboptimal.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' is not marked as suboptimal.' . "\n";
    }
}

END_SCRIPT
