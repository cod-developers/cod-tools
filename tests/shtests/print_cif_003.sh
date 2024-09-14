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

perl -M"${IMPORT_MANAGE_MODULE} qw( new_datablock )" \
     -M"${IMPORT_PRINT_MODULE}  qw( print_cif )" \
<<'END_SCRIPT'
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

# use COD::CIF::Tags::Manage qw( new_datablock );
# use COD::CIF::Tags::Print qw( print_cif );

# Test the way a properly formed loop is printed
my $data_block  = new_datablock( 'data',  '2.0' );
my $save_block  = new_datablock( 'save',  '2.0' );
my $inner_block = new_datablock( 'inner', '2.0' );

push @{$data_block->{save_blocks}}, $save_block;
push @{$save_block->{save_blocks}}, $inner_block;

print_cif( $data_block );

END_SCRIPT
