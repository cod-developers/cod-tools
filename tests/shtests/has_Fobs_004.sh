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
#* Unit test for the COD::CIF::Data::CODFlags::has_Fobs subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* no data items that indicate that the entry has a related diffraction file.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_Fobs );

my $data_block_1 =
{
  'name'   => 'neutral_item',
  'tags'   => [ '_neutral_item' ],
  'loops'  => [],
  'inloop' => {},
  'values' => { '_neutral_item' => [ 'yes' ] },
  'precisions' => {},
  'types'  => { '_neutral_item' => [ 'UQSTRING' ] },
};

my @blocks = (
    $data_block_1,
);

for my $data_block ( @blocks ) {
    my $has_Fobs = has_Fobs( $data_block );
    if ( $has_Fobs ) {
        print 'Data block \'' . $data_block->{'name'} . '\' is marked as having a related diffraction file.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' is not marked as having a related diffraction file.' . "\n";
    }
}

END_SCRIPT
