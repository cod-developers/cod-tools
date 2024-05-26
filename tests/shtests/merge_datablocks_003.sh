#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MANAGE_MODULE=src/lib/perl5/COD/CIF/Tags/Manage.pm
INPUT_MERGE_MODULE=src/lib/perl5/COD/CIF/Tags/Merge.pm
INPUT_PRINT_MODULE=src/lib/perl5/COD/CIF/Tags/Print.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MANAGE_MODULE=$(\
    echo ${INPUT_MANAGE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_MERGE_MODULE=$(\
    echo ${INPUT_MERGE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_PRINT_MODULE=$(\
    echo ${INPUT_PRINT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MANAGE_MODULE} qw( new_datablock set_loop_tag set_tag )" \
     -M"${IMPORT_MERGE_MODULE}  qw( merge_datablocks )" \
     -M"${IMPORT_PRINT_MODULE}  qw( print_cif )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Tags::Merge::merge_datablocks() subroutine.
#* Tests overwriting a looped data item with a non-looped one, when the
#* looped data item is inside a loop with other items.
#**

use strict;
use warnings;

# use COD::CIF::Tags::Manage qw( new_datablock set_loop_tag set_tag );
# use COD::CIF::Tags::Merge qw( merge_datablocks );
# use COD::CIF::Tags::Print qw( print_cif );

my $data_block_single = new_datablock( 'single' );
my $data_block_loop = new_datablock( 'loop' );

set_tag( $data_block_single, '_a', 'value' );
set_loop_tag( $data_block_loop, '_a', undef, [ 1, 2, 3 ] );
set_loop_tag( $data_block_loop, '_b', undef, [ 4, 5, 6 ] );

merge_datablocks( $data_block_single, $data_block_loop, { override_all => 1 } );
print_cif( $data_block_loop );

END_SCRIPT
