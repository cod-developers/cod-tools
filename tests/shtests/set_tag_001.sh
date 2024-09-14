#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MANAGE_MODULE=src/lib/perl5/COD/CIF/Tags/Manage.pm
INPUT_PRINT_MODULE=src/lib/perl5/COD/CIF/Tags/Print.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MANAGE_MODULE=$(\
    echo ${INPUT_MANAGE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_PRINT_MODULE=$(\
    echo ${INPUT_PRINT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MANAGE_MODULE} qw( new_datablock set_tag )" \
     -M"${IMPORT_PRINT_MODULE} qw( print_cif )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Manage::set_tag() subroutine.
#* Tests the way the subroutine behaves when given UTF-8 data.
#* Current behavior for CIF 1.1 is suboptimal as set_tag() does not
#* CIF-encode by itself.
#**

use strict;
use warnings;

use COD::CIF::Tags::Manage qw( new_datablock set_tag );
use COD::CIF::Tags::Print qw( print_cif );

my $data_block_1_1 = new_datablock( 'Šešupė' );
set_tag( $data_block_1_1, '_river', 'Šešupė' );
print_cif( $data_block_1_1 );

my $data_block_2_0 = new_datablock( 'Šešupė' );
$data_block_2_0->{cifversion} = { major => 2, minor => 0 };
set_tag( $data_block_2_0, '_river', 'Šešupė' );
print_cif( $data_block_2_0 );

END_SCRIPT
