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
#* Unit test for the COD::CIF::Tags::Manage::has_unknown_value() subroutine.
#* Tests the way the subroutine considers the value of the 'types' hash.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage;
use COD::Serialise qw( serialiseRef );

##
#data_test
#loop_
#_value
#? '?' "?"
#;?
#;
#;
#?
#;
##
my $data_block =
{
  'tags'   => [ '_values' ],
  'loops'  => [ [ '_values' ] ],
  'inloop' => { '_values' => 0 },
  'values' => {
        '_values' => [ '?', '?', '?', '?', "\n?" ]
   },
  'precisions' => {},
  'types'  => {
    '_values' => [ 'UQSTRING', 'SQSTRING', 'DQSTRING', 'TEXTFIELD', 'TEXTFIELD' ]
   },
};

my $data_name = '_values';

for (my $i = 0; $i < @{$data_block->{'values'}{$data_name}}; $i++) {
    my $unknown = COD::CIF::Tags::Manage::has_unknown_value(
                $data_block,
                $data_name,
                $i
    );
    print "Value at position $i is " . ($unknown ? 'unknown' : 'known') . ".\n";
}

END_SCRIPT
