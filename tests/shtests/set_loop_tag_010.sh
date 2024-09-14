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
#* Tests the way an already existing looped data item is inserted into
#* the same data block it already belongs to.
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
# _replaceable_data_loop
# _c
# 5 1 -1 3
# 4 2 -5 3
# 3 3 -7 2
# 2 4 -3 3
# 1 5 -2 3
##
my $data_block =
{
  'tags'   => [ '_a', '_b', '_replaceable_data_loop', '_c' ],
  'loops'  => [
        [ '_a', '_b', '_replaceable_data_loop', '_c' ],
   ],
  'inloop' => {
        '_a' => 0,
        '_b' => 0,
        '_replaceable_data_loop' => 0,
        '_c' => 0,
  },
  'values' => {
        '_a' => [ 5, 4, 3, 2, 1 ],
        '_b' => [ 1, 2, 3, 4, 5 ],
        '_c' => [ 3, 3, 2, 3, 3 ],
        '_replaceable_data_loop' => [ '-1', '-5', '-7', '-3', '-2' ],
  },
  'precisions' => {
        '_a' => [ undef, undef, undef, undef, undef ],
        '_b' => [ undef, undef, undef, undef, undef ],
        '_replaceable_data_loop' => [ undef, undef, undef, undef, undef ],
        '_c' => [ undef, undef, undef, undef, undef ],
  },
  'types' => {
        '_a' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
        '_b' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
        '_replaceable_data_loop' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
        '_c' => [ 'INT', 'INT', 'INT', 'INT', 'INT' ],
  },
};

my $data_name   = '_replaceable_data_loop';
my $loop_key    = '_b';
my $data_values = [ 1.1, 2.2, 3.3, 4.4, 5.5 ];

COD::CIF::Tags::Manage::set_loop_tag( $data_block,
                                      $data_name,
                                      $loop_key,
                                      $data_values );

serialiseRef( $data_block );

END_SCRIPT
