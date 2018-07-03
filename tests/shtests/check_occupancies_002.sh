#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/Check.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::Check::check_occupancies() subroutine.
#* Tests the way the subroutine behaves when the _atom_site_occupancy
#* data item is not provided.
#**

use strict;
use warnings;

use COD::CIF::Data::Check;
use COD::Serialise qw( serialiseRef );

##
# The $data_block structure represents the following CIF file:
# data_test
# loop_
# _atom_site_label
# A
# B
##

my $data_block =
{
  'tags'   => [ '_atom_site_label' ],
  'loops'  => [ [ '_atom_site_label' ] ],
  'inloop' => {
        '_atom_site_label' => '0',
  },
  'values' => {
        '_atom_site_label' => [ 'A', 'B' ],
  },
  'types' => {
        '_atom_site_label'     => [ 'UQSTRING', 'UQSTRING'  ],
  }
};

my $messages = COD::CIF::Data::Check::check_occupancies(
    $data_block,
);

if (@{$messages}) {
    for (@{$messages}) {
        print "$_\n";
    }
} else {
    print "No audit messages returned.\n";
}

END_SCRIPT
