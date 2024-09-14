#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Tags/Manage.pm
INPUT_SERIALISE_MODULE=src/lib/perl5/COD/Serialise.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_SERIALISE_MODULE=$(\
    echo ${INPUT_SERIALISE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE}" \
     -M"${IMPORT_SERIALISE_MODULE} qw( serialiseRef )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Manage::set_loop_tag() subroutine.
#* Tests the way a new data item is inserted into the data block when
#* the loop key matches a name of a data item existing in a different
#* loop.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Manage;
# use COD::Serialise qw( serialiseRef );

##
# The $data_block structure represents the following CIF file:
# data_test
# loop_
# _a
# _b
# _c
# 5 1 3
# 4 2 3
# 3 3 2
# 2 4 3
# 1 5 3
##
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
  },
  'precisions' => {
        '_a' => [ undef, undef, undef, undef, undef ],
        '_b' => [ undef, undef, undef, undef, undef ],
        '_c' => [ undef, undef, undef, undef, undef ],
  },
  'types' => {
        '_a' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
        '_b' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
        '_c' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
   },
};

my $data_name   = '_new_data_item';
my $loop_key    = '_a';
my $data_values = [ 1.1, 2.2, 3.3, 4.4, 5.5 ];

COD::CIF::Tags::Manage::set_loop_tag( $data_block,
                                      $data_name,
                                      $loop_key,
                                      $data_values );

serialiseRef( $data_block );

END_SCRIPT
