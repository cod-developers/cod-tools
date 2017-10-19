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
#* Unit test for the COD::CIF::Tags::Manage::set_loop_tag() subroutine.
#* Tests the way the subroutine behaves when called on a CIF file that
#* previously contained only unlooped values.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage;
use COD::Serialise qw( serialiseRef );

##
# The $data_block structure represents the following CIF file:
# data_test
# _a        3
# _b        2
# _c        z
##
my $data_block =
{
  'tags'   => [ '_a', '_b', '_c' ],
  'loops'  => [ ],
  'inloop' => {},
  'values' => {
        '_a' => [ '3' ],
        '_b' => [ '2' ],
        '_c' => [ 'z' ],
   },
  'precisions' => {
        '_a' => [ undef ],
        '_b' => [ undef ],
  },
  'types' => {
        '_a' => [ 'INT' ],
        '_b' => [ 'INT' ],
        '_c' => [ 'UQSTRING' ],
   },
};

my $data_name   = '_new_looped_item';
my $loop_key    = $data_name;
my $data_values = [ 1.1, 2.2, 3.3, 4.4, 5.5 ];

COD::CIF::Tags::Manage::set_loop_tag( $data_block,
                                      $data_name,
                                      $loop_key,
                                      $data_values );

serialiseRef( $data_block );

END_SCRIPT
