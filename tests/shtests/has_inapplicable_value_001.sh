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
#* Unit test for the COD::CIF::Tags::Manage::has_inapplicable_value() subroutine.
#* Tests the way the subroutine considers the value of the 'values' hash.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage;
use COD::Serialise qw( serialiseRef );

##
#data_test
#_value inapplicable
##
my $data_block =
{
  'tags'   => [ '_value' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => { '_value' => [ 'inapplicable' ] },
  'precisions' => {},
  'types'  => { '_value' => [ 'UQSTRING' ]},
};

my $data_name = '_value';

my $inapplicable = COD::CIF::Tags::Manage::has_inapplicable_value(
                    $data_block,
                    $data_name,
                    0 );

print "Value is " . ($inapplicable ? 'inapplicable' : 'applicable') . ".\n";

END_SCRIPT
