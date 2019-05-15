#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MANAGE='src/lib/perl5/COD/CIF/Tags/Manage.pm'
INPUT_PRINT='src/lib/perl5/COD/CIF/Tags/Print.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Unit test for the COD::CIF::Tags::Print::print_cif() subroutine.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage qw( new_datablock );
use COD::CIF::Tags::Print qw( print_cif );

# Test the way a properly formed loop is printed
my $data_block  = new_datablock( 'data',  '2.0' );
my $save_block  = new_datablock( 'save',  '2.0' );
my $inner_block = new_datablock( 'inner', '2.0' );

push @{$data_block->{save_blocks}}, $save_block;
push @{$save_block->{save_blocks}}, $inner_block;

print_cif( $data_block );

END_SCRIPT
