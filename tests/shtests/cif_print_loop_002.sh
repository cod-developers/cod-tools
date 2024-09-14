#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Tags/Print.pm
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
#  Unit test for the COD::CIF::Tags::Print::print_loop() subroutine.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Print;

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

COD::CIF::Tags::Print::print_loop( $data_block, 0 );
COD::CIF::Tags::Print::print_loop( $data_block, 1 );

END_SCRIPT
