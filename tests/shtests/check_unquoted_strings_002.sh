#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/Check.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( check_unquoted_strings )" \
<<'END_SCRIPT'
#**
#* Unit test for the COD::CIF::Data::Check::check_unquoted_strings() subroutine.
#* Tests the way the long values are trunkated in the output messages.
#**

use strict;
use warnings;

use COD::CIF::Data::Check qw( check_unquoted_strings );

##
# The $data_block structure represents the following CIF file:
# data_test
# _data_name_1                          short-value'
# _data_name_2                          ;somewhat-longer-value-that-will-be-cut
# _data_name_3                          a-very-long-value-that-will-definitely-get-cut;
#
##

my $data_block =
{
  'tags'   => [
        '_data_name_1',
        '_data_name_2',
        '_data_name_3',
  ],
  'loops'  => [ ],
  'inloop' => { },
  'values' => {
        '_data_name_1' => [ "short-value'" ],
        '_data_name_2' => [ ";somewhat-longer-value-that-will-be-cut" ],
        '_data_name_3' => [ "a-very-long-value-that-will-definitely-get-cut;" ],
  },
  'precisions' => {
        '_data_name_1' => [ undef ],
        '_data_name_2' => [ undef ],
        '_data_name_3' => [ undef ],
  },
  'types' => {
        '_data_name_1' => [ 'UQSTRING' ],
        '_data_name_2' => [ 'UQSTRING' ],
        '_data_name_3' => [ 'UQSTRING' ],
  }
};

my $messages = COD::CIF::Data::Check::check_unquoted_strings( $data_block );

if (@{$messages}) {
    for (@{$messages}) {
        print "$_\n";
    }
} else {
    print "No audit messages returned.\n";
}

END_SCRIPT
