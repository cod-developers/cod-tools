#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Tags/Manage.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Manage::has_special_value() subroutine.
#* Tests the way the subroutine considers the value of the 'values' hash.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage;
use COD::Serialise qw( serialiseRef );

##
#data_test
#loop_
#_value
#special
#?
#.
#'?'
#"."
##
my $data_block =
{
  'tags'   => [ '_value' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_value' => [ 'special', '?', '.', '?', '.' ] },
  'precisions' => {},
  'types'  => {
    '_value' => [ 'UQSTRING', 'UQSTRING', 'UQSTRING', 'SQSTRING', 'DQSTRING' ]
   },
};

my $data_name = '_value';

for (my $i = 0; $i < @{$data_block->{'values'}{$data_name}}; $i++) {
    my $special = COD::CIF::Tags::Manage::has_special_value(
                $data_block,
                $data_name,
                $i
    );
    print "Value at position $i is " .
           ($special ? 'special' : 'not special') . ".\n";
}

END_SCRIPT
