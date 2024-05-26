#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_FLAGS_MODULE=src/lib/perl5/COD/CIF/Data/CODFlags.pm
INPUT_MANAGE_MODULE=src/lib/perl5/COD/CIF/Tags/Manage.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_FLAGS_MODULE=$(\
    echo ${INPUT_FLAGS_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_MANAGE_MODULE=$(\
    echo ${INPUT_MANAGE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_FLAGS_MODULE}  qw( has_superspace_group )" \
     -M"${IMPORT_MANAGE_MODULE} qw( new_datablock )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::has_superspace_group() subroutine.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_superspace_group );
use COD::CIF::Tags::Manage qw( new_datablock );

my @data_blocks;
my $data_block;

# Contains no data about atoms.
$data_block = new_datablock( '[NO]_empty' );
push @data_blocks, $data_block;

my @ssg_data_items = qw(
    _space_group_ssg_name
    _space_group_ssg_name_IT
    _space_group_ssg_name_WJJ
    _space_group_ssg_IT_number
    _space_group_symop_ssg_id
    _space_group_symop_ssg_operation_algebraic
    _geom_angle_site_ssg_symmetry_1
    _geom_angle_site_ssg_symmetry_2
    _geom_angle_site_ssg_symmetry_3
    _geom_bond_site_ssg_symmetry_1
    _geom_bond_site_ssg_symmetry_2
);

# Contains a superspace group related data item with any value.
for my $data_item (@ssg_data_items) {
    $data_block = new_datablock( "[YES]_$data_item" );
    $data_block->{'values'}{$data_item} = '?';
    push @data_blocks, $data_block;
}

print "Output\tData block name\n";
for my $test_case (@data_blocks) {
    print has_superspace_group($test_case) . "\t" . $test_case->{'name'} . "\n";
}

END_SCRIPT
