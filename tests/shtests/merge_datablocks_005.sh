#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Tags/Merge.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Merge::merge_datablocks() subroutine.
#* Tests overwriting a looped data item list with a shorter looped one.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage qw( new_datablock set_loop_tag set_tag );
use COD::CIF::Tags::Merge qw( merge_datablocks );
use COD::CIF::Tags::Print qw( print_cif );

my $data_block_short = new_datablock( 'short' );
my $data_block_long  = new_datablock( 'long' );

set_loop_tag( $data_block_short, '_a', undef, [ 0, 1 ] );
set_loop_tag( $data_block_short, '_b', undef, [ 2, 3 ] );
set_loop_tag( $data_block_long,  '_a', undef, [ 4, 5, 6 ] );
set_loop_tag( $data_block_long,  '_b', undef, [ 7, 8, 9 ] );

merge_datablocks( $data_block_short, $data_block_long, { override_all => 1 } );
print_cif( $data_block_long );

END_SCRIPT
