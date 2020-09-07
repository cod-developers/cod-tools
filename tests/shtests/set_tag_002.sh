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
#* Unit test for the COD::CIF::Tags::Manage::set_tag() subroutine.
#* Tests the way the subroutine outputs a data value with \r.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage qw( new_datablock set_tag );
use COD::CIF::Tags::Print qw( print_cif );

my $data_block_1_1 = new_datablock( 'newline' );
set_tag( $data_block_1_1, '_data_name', "value with \r newline" );
print_cif( $data_block_1_1 );

my $data_block_2_0 = new_datablock( 'newline' );
$data_block_2_0->{cifversion} = { major => 2, minor => 0 };
set_tag( $data_block_2_0, '_data_name', "value with \r newline" );
print_cif( $data_block_2_0 );

END_SCRIPT
