#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/Check.pm
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
#* Unit test for the COD::CIF::Data::Check::check_occupancies() subroutine.
#* Tests the way the subroutine behaves when the _atom_site_occupancy
#* contains special values (unknown and inapplicable CIF values) and the
#* atoms are not explicitly marked as being dummy atoms.
#**

use strict;
use warnings;

# use COD::CIF::Data::Check;

##
# The $data_block structure represents the following CIF file:
# data_test
# loop_
# _atom_site_label
# _atom_site_occupancy
# A .
# B ?
##

my $data_block =
{
  'tags'   => [ '_atom_site_label', '_atom_site_occupancy' ],
  'loops'  => [ [ '_atom_site_label', '_atom_site_occupancy' ] ],
  'inloop' => {
        '_atom_site_label' => '0',
        '_atom_site_occupancy' => '0',
  },
  'values' => {
        '_atom_site_label' => [ 'A', 'B' ],
        '_atom_site_occupancy' => [ '.', '?' ],
  },
  'types' => {
        '_atom_site_label'     => [ 'UQSTRING', 'UQSTRING' ],
        '_atom_site_occupancy' => [ 'UQSTRING', 'UQSTRING' ],
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
