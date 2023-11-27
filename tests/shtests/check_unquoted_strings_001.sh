#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/Check.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#**
#* Unit test for the COD::CIF::Data::Check::check_unquoted_strings() subroutine.
#* Tests the way the subroutine recognises and skips certain data items.
#**

use strict;
use warnings;

use COD::CIF::Data::Check qw( check_unquoted_strings );

##
# The $data_block structure represents the following CIF file:
# data_test
# _cod_data_source_block                ;block'
# _cod_original_sg_symbol_Hall          P1'
# _cod_original_formula_sum             ;C12H12
# 
##

my $data_block =
{
  'tags'   => [
        '_cod_data_source_block',
        '_cod_original_sg_symbol_Hall',
        '_cod_original_formula_sum',
  ],
  'loops'  => [ ],
  'inloop' => { },
  'values' => {
        '_cod_data_source_block' => [ ";block'" ],
        '_cod_original_sg_symbol_Hall' => [ "P1'" ],
        '_cod_original_formula_sum' => [ ';C12H12' ],
  },
  'precisions' => {
        '_cod_data_source_block' => [ undef ],
        '_cod_original_sg_symbol_Hall' => [ undef ],
        '_cod_original_formula_sum' => [ undef ],
  },
  'types' => {
        '_cod_data_source_block' => [ 'UQSTRING' ],
        '_cod_original_sg_symbol_Hall' => [ 'UQSTRING' ],
        '_cod_original_formula_sum' => [ 'UQSTRING' ],
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
