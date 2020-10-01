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
#* Unit test for the COD::CIF::Data::CODFlags::has_attached_hydrogens
#* subroutine.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_attached_hydrogens );

my $data_block_1 =
{
  'name'   => 'test_1',
  'tags'   => [],
  'loops'  => [],
  'inloop' => {},
  'values' => {},
  'precisions' => {},
  'types'  => {},
};

my $data_block_2 =
{
  'name'   => 'test_2',
  'tags'   => [ '_atom_site_attached_hydrogens' ],
  'loops'  => [ [ '_atom_site_attached_hydrogens' ] ],
  'inloop' => { '_atom_site_attached_hydrogens' => 0 },
  'values' => { '_atom_site_attached_hydrogens' => [ '?', '.' ] },
  'precisions' => {},
  'types'  => { '_atom_site_attached_hydrogens' => [ 'UQSTRING', 'UQSTRING' ] },
};

my $data_block_3 =
{
  'name'   => 'test_3',
  'tags'   => [ '_atom_site_attached_hydrogens' ],
  'loops'  => [ [ '_atom_site_attached_hydrogens' ] ],
  'inloop' => { '_atom_site_attached_hydrogens' => 0 },
  'values' => { '_atom_site_attached_hydrogens' => [ '0' ] },
  'precisions' => {},
  'types'  => { '_atom_site_attached_hydrogens' => [ 'INTEGER' ] },
};

my $data_block_4 =
{
  'name'   => 'test_4',
  'tags'   => [ '_atom_site_attached_hydrogens' ],
  'loops'  => [ [ '_atom_site_attached_hydrogens' ] ],
  'inloop' => { '_atom_site_attached_hydrogens' => 0 },
  'values' => { '_atom_site_attached_hydrogens' => [ '1' ] },
  'precisions' => {},
  'types'  => { '_atom_site_attached_hydrogens' => [ 'INTEGER' ] },
};

my @blocks = (
    $data_block_1,
    $data_block_2,
    $data_block_3,
    $data_block_4,
);

for my $data_block ( @blocks ) {
    my $has_attached_hydrogens = has_attached_hydrogens( $data_block );
    if ( $has_attached_hydrogens ) {
        print 'Data block \'' . $data_block->{'name'} . '\' has attached hydrogens.' . "\n";
    } else {
        print 'Data block \'' . $data_block->{'name'} . '\' does not have attached hydrogens.' . "\n";
    }
}

END_SCRIPT
