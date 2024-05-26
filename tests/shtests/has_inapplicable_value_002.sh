#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Tags/Manage.pm
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
#* Unit test for the COD::CIF::Tags::Manage::has_inapplicable_value() subroutine.
#* Tests the way the subroutine considers the value of the 'types' hash.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Manage;

##
#data_test
#loop_
#_value
#. '.' "."
#;.
#;
#;
#.
#;
##
my $data_block =
{
  'tags'   => [ '_values' ],
  'loops'  => [ [ '_values' ] ],
  'inloop' => { '_values' => 0 },
  'values' => {
        '_values' => [ '.', '.', '.', '.', "\n." ]
   },
  'precisions' => {},
  'types'  => {
    '_values' => [ 'UQSTRING', 'SQSTRING', 'DQSTRING', 'TEXTFIELD', 'TEXTFIELD' ]
   },
};

my $data_name = '_values';

for (my $i = 0; $i < @{$data_block->{'values'}{$data_name}}; $i++) {
    my $inapplicable = COD::CIF::Tags::Manage::has_inapplicable_value(
                $data_block,
                $data_name,
                $i
    );
    print "Value at position $i is " .
           ($inapplicable ? 'inapplicable' : 'applicable') . ".\n";
}

END_SCRIPT
