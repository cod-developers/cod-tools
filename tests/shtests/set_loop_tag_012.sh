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
#* Tests the way data item insertion into the loop affects the overall
#* order of loops in the data block.
#*
#* Where possible the loops should not change their order of appearance:
#* 1) insertion of new data items should not affect the loop order;
#* 2) newly formed loops should appear at the end of the data block
#*    regardless if they are formed from new data items or the already
#*    existing ones.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Manage;
# use COD::Serialise qw( serialiseRef );

##
# The $data_block structure represents the following CIF file:
# data_test
# loop_
# _remain_first
# a b c d
# loop_
# _a
# _b
# _c
# 5 1 3
# 4 2 3
# 3 3 2
# 2 4 3
# 1 5 3
# _unlooped_data_item '42.0'
##
my $data_block =
{
  'tags'   =>   [ '_remain_first', '_a', '_b', '_c', '_unlooped_data_item' ],
  'loops'  => [ [ '_remain_first' ], [ '_a', '_b', '_c' ] ],
  'inloop' => {
        '_remain_first' => 0,
        '_a' => 1,
        '_b' => 1,
        '_c' => 1,
  },
  'values' => {
        '_remain_first' => [ 'a', 'b', 'c', 'd' ],
        '_a' => [ 5, 4, 3, 2, 1 ],
        '_b' => [ 1, 2, 3, 4, 5 ],
        '_c' => [ 3, 3, 2, 3, 3 ],
        '_unlooped_data_item' => [ 42.0 ],
  },
  'precisions' => {
        '_a' => [ undef, undef, undef, undef, undef ],
        '_b' => [ undef, undef, undef, undef, undef ],
        '_c' => [ undef, undef, undef, undef, undef ],
        '_unlooped_data_item'  => [ undef ],
  },
  'types' => {
        '_remain_first' => [ 'UQSTRING', 'UQSTRING', 'UQSTRING', 'UQSTRING' ],
        '_a' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
        '_b' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
        '_c' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
        '_unlooped_data_item' => [ 'FLOAT' ],
      },
};

my $data_name   = '_remain_first';
my $loop_key    = $data_name;
my $data_values = [ 2 ];

COD::CIF::Tags::Manage::set_loop_tag( $data_block,
                                      $data_name,
                                      $loop_key,
                                      $data_values );

serialiseRef( $data_block );

END_SCRIPT
