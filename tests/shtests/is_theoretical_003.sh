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
#* Unit test for the COD::CIF::Data::CODFlags::is_theoretical subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* various data items all of which explicitly state that the entry is not
#* a theoretically determined one.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( is_theoretical );

my $data_block_1 =
{
  'name'   => 'theoretical_item_1',
  'tags'   => [ '_cod_structure.determination_method',
                '_cod_structure_determination_method',
                '_cod_struct_determination_method', ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_cod_structure.determination_method' => [ 'powder diffraction' ],
                '_cod_structure_determination_method' => [ 'powder diffraction' ],
                '_cod_struct_determination_method'    => [ 'powder diffraction' ], },
  'precisions' => {},
  'types'  => { '_cod_structure.determination_method' => [ 'UQSTRING' ],
                '_cod_structure_determination_method' => [ 'UQSTRING' ],
                '_cod_struct_determination_method'    => [ 'UQSTRING' ], },
};

my @blocks = (
    $data_block_1,
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
