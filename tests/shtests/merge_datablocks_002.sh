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
#* Tests overwriting a non-looped data item with a looped one.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage qw( new_datablock set_loop_tag set_tag );
use COD::CIF::Tags::Merge qw( merge_datablocks );
use COD::CIF::Tags::Print qw( print_cif );

my $data_block_single = new_datablock( 'single' );
my $data_block_loop = new_datablock( 'loop' );

set_tag( $data_block_single, '_data_name', 'value' );
set_loop_tag( $data_block_loop, '_data_name', undef, [ 1, 2, 3 ] );

merge_datablocks( $data_block_loop, $data_block_single, { override_all => 1 } );
print_cif( $data_block_single );

END_SCRIPT
