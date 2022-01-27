#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_CODFlags='src/lib/perl5/COD/CIF/Data/CODFlags.pm'
INPUT_Manage='src/lib/perl5/COD/CIF/Tags/Manage.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODFlags::has_non_hydrogen_calc_sites()
#* subroutine.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_non_hydrogen_calc_sites );
use COD::CIF::Tags::Manage qw( new_datablock );

my @data_blocks;
my $data_block;

# Contains no data about atoms.
$data_block = new_datablock( '[NO]_empty' );
push @data_blocks, $data_block;

# Does not contain the '_atom_site_calc_flag' data item.
$data_block = new_datablock( '[NO]_no_atom_site_calc_flag' );
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
push @data_blocks, $data_block;

# Contains neither the '_atom_site_label' nor
# the '_atom_site_type_symbol' data item.
$data_block = new_datablock( '[NO]_no_atom_type_information' );
$data_block->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'c', 'calc' ];
push @data_blocks, $data_block;

# Contains the '_atom_site_label' data item,
# but not the '_atom_site_type_symbol' data item.
$data_block = new_datablock( '[NO]_only_atom_site_label' );
$data_block->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd', ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4' ];
push @data_blocks, $data_block;

# Contains the '_atom_site_label' data item,
# but not the '_atom_site_type_symbol' data item.
$data_block = new_datablock( '[YES]_only_atom_site_label' );
$data_block->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'c', 'd' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4' ];
push @data_blocks, $data_block;

# Contains the '_atom_site_label' data item,
# but not the '_atom_site_type_symbol' data item.
$data_block = new_datablock( '[NO]_only_atom_site_type_symbol' );
$data_block->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd', ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'C' ];
push @data_blocks, $data_block;

# Contains the '_atom_site_type_symbol' data item,
# but not the '_atom_site_label' data item.
$data_block = new_datablock( '[YES]_only_atom_site_type_symbol' );
$data_block->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'c', 'd' ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'C' ];
push @data_blocks, $data_block;

# Contains no atoms with the 'c' or 'calc' flag value.
$data_block = new_datablock( '[NO]_no_calc_atoms' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4' ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'C' ];
push @data_blocks, $data_block;

# Contains a hydrogen atom with the 'c' flag value.
$data_block = new_datablock( '[NO]_H_atom_c_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd', 'c' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'C', 'H' ];
push @data_blocks, $data_block;

# Contains a hydrogen atom with the 'calc' flag value.
$data_block = new_datablock( '[NO]_H_atom_calc_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd', 'calc' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'C', 'H' ];
push @data_blocks, $data_block;

# Contains a deuterium atom with the 'calc' flag value.
$data_block = new_datablock( '[NO]_D_atom_calc_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'calc', 'd' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'D1', 'C4' ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'D', 'C' ];
push @data_blocks, $data_block;

# Contains a tritium atom with the 'calc' flag value.
$data_block = new_datablock( '[NO]_T_atom_calc_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'calc', 'd' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'T1', 'C4' ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'T', 'C' ];
push @data_blocks, $data_block;

# Contains a carbon atom with the 'c' flag value.
$data_block = new_datablock( '[YES]_C_atom_c_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'c', 'd', 'c' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'C', 'H' ];
push @data_blocks, $data_block;

# Contains a carbon atom with the 'calc' flag value.
$data_block = new_datablock( '[YES]_C_atom_calc_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'c', 'd', 'calc' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
$data_block->{'values'}{'_atom_site_type_symbol'} = [ 'C', 'C', 'C', 'C', 'H' ];
push @data_blocks, $data_block;

print "Output\tData block name\n";
for my $test_case (@data_blocks) {
    print has_non_hydrogen_calc_sites($test_case) . "\t" .
            $test_case->{'name'} . "\n";
}

END_SCRIPT
