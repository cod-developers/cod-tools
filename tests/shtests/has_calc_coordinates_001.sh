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
#* Unit test for the COD::CIF::Data::CODFlags::has_calc_coordinates() subroutine.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_calc_coordinates );
use COD::CIF::Tags::Manage qw( new_datablock );

my @data_blocks;
my $data_block;

# Contains no data about atoms.
$data_block = new_datablock( '[NO]_empty' );
push @data_blocks, $data_block;

# Does not contain the '_atom_site_calc_flag' data atom.
$data_block = new_datablock( '[NO]_no_atom_site_calc_flag' );
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
push @data_blocks, $data_block;

# Does not contain the '_atom_site_label' data atom.
$data_block = new_datablock( '[NO]_atom_site_label' );
$data_block->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'c', 'calc' ];
push @data_blocks, $data_block;

# Contains no atoms with the 'c' or 'calc' flag value.
$data_block = new_datablock( '[NO]_no_calc_atoms' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4' ];
push @data_blocks, $data_block;

# Contains hydrogen atom with the 'c' flag value.
$data_block = new_datablock( '[NO]_H_atom_c_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd', 'c' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
push @data_blocks, $data_block;

# Contains hydrogen atom with the 'calc' flag value.
$data_block = new_datablock( '[NO]_H_atom_calc_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd', 'calc' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
push @data_blocks, $data_block;

# Contains a carbon atom with the 'c' flag value.
$data_block = new_datablock( '[YES]_C_atom_c_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'c', 'd', 'c' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
push @data_blocks, $data_block;

# Contains a carbon atom with the 'calc' flag value.
$data_block = new_datablock( '[YES]_C_atom_calc_flag' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'c', 'd', 'calc' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
push @data_blocks, $data_block;

for my $test_case (@data_blocks) {
    if (has_calc_coordinates($test_case)) {
        print 'Data block \'' . $test_case->{'name'} . '\' has heavy atoms with calculated coordinates.' . "\n";
    } else {
        print 'Data block \'' . $test_case->{'name'} . '\' does not have heavy atoms with calculated coordinates.' . "\n";
    }
}

END_SCRIPT
