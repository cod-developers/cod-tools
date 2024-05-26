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
#* Unit test for the COD::CIF::Data::Check::check_mandatory_presence()
#* subroutine. Tests the way the subroutine behaves when not all of the
#* mandatory data names are present in the CIF file.
#**

use strict;
use warnings;

# use COD::CIF::Data::Check;

##
# The $data_block structure represents the following CIF file:
# data_test
# _tag_1          1
# _tag_2          2
# loop_
# _tag_3
# _tag_4
# 3 4
# 5 6
##

my $data_block =
{
  'tags'   => [ '_tag_1', '_tag_2', '_tag_3', '_tag_4' ],
  'loops'  => [ [ '_tag_3', '_tag_4' ] ],
  'inloop' => {
        '_tag_3' => '0',
        '_tag_4' => '0',
  },
  'values' => {
        '_tag_1' => [ '1' ],
        '_tag_2' => [ '2' ],
        '_tag_3' => [ '3', '5' ],
        '_tag_4' => [ '4', '6' ],
  },
  'precisions' => {
        '_tag_1' => [ undef ],
        '_tag_2' => [ undef ],
        '_tag_3' => [ undef, undef ],
        '_tag_4' => [ undef, undef ],
  },
  'types' => {
        '_tag_1' => [ 'INT' ],
        '_tag_2' => [ 'INT' ],
        '_tag_3' => [ 'INT', 'INT' ],
        '_tag_4' => [ 'INT', 'INT' ],
  }
};

my $data_names = {
    '_tag_2'        => 1,
    '_tag_4'        => 1,
    '_tag_missing'  => 1,
    '_tag_not_here' => 1,
};

my $messages = COD::CIF::Data::Check::check_mandatory_presence(
    $data_block,
    $data_names
);

if (@{$messages}) {
    for (@{$messages}) {
        print "$_\n";
    }
} else {
    print "No audit messages returned.\n";
}

END_SCRIPT
