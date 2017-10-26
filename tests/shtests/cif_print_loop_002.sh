#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Tags/Print.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Unit test for the COD::CIF::Tags::Print::print_loop() subroutine.
#**

use strict;
use warnings;

use COD::CIF::Tags::Print;

# Test the way a malformed data block loop with differing number of data values
# in the same loop is handled.
my $data_block =
{
  'tags'   =>   [ '_a', '_b', '_c', '_d', '_e' ],
  'loops'  => [ [ '_a', '_b', '_c' ], [ '_d', '_e' ] ],
  'inloop' => {
        '_a' => 0,
        '_b' => 0,
        '_c' => 0,
        '_d' => 1,
        '_e' => 1,
  },
  'values' => {
        '_a' => [ 1, 4, 5 ],
        '_b' => [ 1, 2, 3, 4, 5 ],
        '_c' => [ 2 ],
        '_d' => [],
        '_e' => [],
   }
};

COD::CIF::Tags::Print::print_loop( '_a', 0, $data_block );
COD::CIF::Tags::Print::print_loop( $data_block, 1 );

END_SCRIPT
