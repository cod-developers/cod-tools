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
#* Unit test for the COD::CIF::Tags::Manage::has_numeric_value() subroutine.
#* Tests the way the subroutine considers the value of the 'values' hash.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Manage;

##
#data_test
#loop_
#_value
#text
#5
#5(5)
#5.5
#5.5(5)
#'12'
#"12(5)"
#;42
#;
##
my $data_block =
{
  'tags'   => [ '_value' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_value' => [ 'text', '5', '5(5)', '5.5', '5.5(5)', 12, '12(5)', 42, 30 ] },
  'precisions' => {},
  'types'  => {
    '_value' => [ 'UQSTRING', 'INT', 'INT', 'FLOAT', 'FLOAT', 'SQSTRING', 'DQSTRING', 'TEXTFIELD', undef ]
   },
};

my $data_name = '_value';

for (my $i = 0; $i < @{$data_block->{'values'}{$data_name}}; $i++) {
    my $numeric = COD::CIF::Tags::Manage::has_numeric_value(
                $data_block,
                $data_name,
                $i
    );
    print "Value at position $i is " .
           ($numeric ? 'numeric' : 'not numeric') . ".\n";
}

END_SCRIPT
