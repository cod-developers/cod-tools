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

my $data_block = new_datablock( 'newline' );
set_tag( $data_block, '_data_name', "value with \r newline" );
print_cif( $data_block );

END_SCRIPT
