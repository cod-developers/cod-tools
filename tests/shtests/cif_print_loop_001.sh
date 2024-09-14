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

# Test the way a properly formed loop is printed
my $data_block =
{
  'tags'   =>   [ '_a', '_b', '_c' ],
  'loops'  => [ [ '_a', '_b', '_c' ] ],
  'inloop' => {
        '_a' => 0,
        '_b' => 0,
        '_c' => 0,
  },
  'values' => {
        '_a' => [ 5, 4, 3, 2, 1 ],
        '_b' => [ 1, 2, 3, 4, 5 ],
        '_c' => [ 3, 3, 2, 3, 3 ],
   }
};

COD::CIF::Tags::Print::print_loop( $data_block, 0 );

END_SCRIPT
