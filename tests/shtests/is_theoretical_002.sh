#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODFlags.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( is_theoretical )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::is_theoretical subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* various data items some of which state that the entry is a theoretically
#* determined one as some of which contradict this statement.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODFlags qw( is_theoretical );

my $data_block_1 =
{
  'name'   => 'theoretical_item_1',
  'tags'   => [ '_cod_structure.determination_method',
                '_cod_structure_determination_method',
                '_cod_struct_determination_method', ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_structure.determination_method' => [ 'theoretical' ],
                '_cod_structure_determination_method' => [ 'single crystal' ],
                '_cod_struct_determination_method'    => [ 'powder diffraction' ], },
  'precisions' => {},
  'types'  => { '_cod_structure.determination_method' => [ 'UQSTRING' ],
                '_cod_structure_determination_method' => [ 'UQSTRING' ],
                '_cod_struct_determination_method'    => [ 'UQSTRING' ], },
};

my $data_block_2 =
{
  'name'   => 'theoretical_item_2',
  'tags'   => [ '_cod_structure.determination_method',
                '_cod_structure_determination_method',
                '_cod_struct_determination_method', ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_structure.determination_method' => [ 'single crystal' ],
                '_cod_structure_determination_method' => [ 'theoretical' ],
                '_cod_struct_determination_method'    => [ 'powder diffraction' ], },
  'precisions' => {},
  'types'  => { '_cod_structure.determination_method' => [ 'UQSTRING' ],
                '_cod_structure_determination_method' => [ 'UQSTRING' ],
                '_cod_struct_determination_method'    => [ 'UQSTRING' ], },
};

my $data_block_3 =
{
  'name'   => 'theoretical_item_3',
  'tags'   => [ '_cod_structure.determination_method',
                '_cod_structure_determination_method',
                '_cod_struct_determination_method', ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_structure.determination_method' => [ 'single crystal' ],
                '_cod_structure_determination_method' => [ 'powder diffraction' ],
                '_cod_struct_determination_method'    => [ 'theoretical' ], },
  'precisions' => {},
  'types'  => { '_cod_structure.determination_method' => [ 'UQSTRING' ],
                '_cod_structure_determination_method' => [ 'UQSTRING' ],
                '_cod_struct_determination_method'    => [ 'UQSTRING' ], },
};

my @blocks = (
    $data_block_1,
    $data_block_2,
    $data_block_3,
);

for my $data_block ( @blocks ) {
    my $is_theoretical = is_theoretical( $data_block );
    if ( $is_theoretical ) {
        print 'Data block \'' . $data_block->{'name'} . '\' is marked as describing a theoretically calculated entry.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' is not marked as describing a theoretically calculated entry.' . "\n";
    }
}

END_SCRIPT
