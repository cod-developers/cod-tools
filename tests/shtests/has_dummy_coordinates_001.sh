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
#* Unit test for the COD::CIF::Data::CODFlags::has_dummy_coordinates()
#* subroutine.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_dummy_coordinates );
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

# Does not contain the '_atom_site_label' data item or the 'dum' flag.
$data_block = new_datablock( '[NO]_atom_site_label_no_dum' );
$data_block->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'c', 'c' ];
push @data_blocks, $data_block;

# Does not contain the '_atom_site_label' data item, but contains the 'dum' flag.
$data_block = new_datablock( '[YES]_atom_site_label_with_dum' );
$data_block->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'dum', 'c', 'c' ];
push @data_blocks, $data_block;

# Contains no atoms with the 'dum' flag value.
$data_block = new_datablock( '[NO]_no_dummy_atoms' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd', 'c' ] ;
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ] ;
push @data_blocks, $data_block;

# Contains an atom with the 'dum' flag value.
$data_block = new_datablock( '[YES]_with_dummy_atom' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'dum', 'c' ] ;
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ] ;
push @data_blocks, $data_block;

# Data block was named "Integers". Test targer unclear.
$data_block = new_datablock( '[YES?]_integers' );
$data_block->{'values'}{'_atom_site_calc_flag'} = [ 'd', 'd', 'dum', 'c', 'c' ];
$data_block->{'types'}{'_atom_site_calc_flag'} = [ 'UQSTRING', 'UQSTRING', 'INTEGER', 'UQSTRING', 'UQSTRING' ];
$data_block->{'values'}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ];
push @data_blocks, $data_block;

for my $test_case (@data_blocks) {
    if (has_dummy_coordinates($test_case)) {
        print 'Data block \'' . $test_case->{'name'} . '\' has atoms with dummy coordinates.' . "\n";
    } else {
        print 'Data block \'' . $test_case->{'name'} . '\' does not have atoms with dummy coordinates.' . "\n";
    }
}


END_SCRIPT
