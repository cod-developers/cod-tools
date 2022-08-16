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
#* Unit test for the COD::CIF::Data::CODFlags::has_unmodelled_solvent_molecules()
#* subroutine. Test the way the '_platon_squeeze_void_count_electrons'
#* data item that appears as part of the '_shelx_fab_file' data item
#* value is recognised and handled.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_unmodelled_solvent_molecules );
use COD::CIF::Tags::Manage qw( new_datablock );

my @data_blocks;
my $data_block;

# Contains no data about unmodelled solvent molecules.
$data_block = new_datablock( '[NO]_empty' );
push @data_blocks, $data_block;

# Contains the '_shelx_fab_file' data item.
# Value of the '_shelx_fab_file' data item does not contain
# the '_platon_squeeze_void_count_electrons' string.
$data_block = new_datablock( '[NO]_shelx_fab_file_no_platon_squeeze' );
$data_block->{'values'}{'_shelx_fab_file'} = [ 'Fab file contents' ];
push @data_blocks, $data_block;

# Contains the '_shelx_fab_file' data item.
# The single line value of the '_shelx_fab_file' data item
# contains the '_platon_squeeze_void_count_electrons' string.
$data_block = new_datablock( '[YES]_single_line_shelx_fab_file_with_platon_squeeze' );
$data_block->{'values'}{'_shelx_fab_file'} = [
    '_platon_squeeze_void_count_electrons'
];
push @data_blocks, $data_block;

# Contains the '_shelx_fab_file' data item.
# The multiline value of the '_shelx_fab_file' data item
# contains the '_platon_squeeze_void_count_electrons' string.
$data_block = new_datablock( '[YES]_multiline_shelx_fab_file_with_platon_squeeze' );
$data_block->{'values'}{'_shelx_fab_file'} = [
    (
        "Fab file with\n" .
        "the _platon_squeeze_void_count_electrons tag\n" .
        "on another line"
    )
];
push @data_blocks, $data_block;

print "Output\tData block name\n";
for my $test_case (@data_blocks) {
    print has_unmodelled_solvent_molecules($test_case) . "\t" . $test_case->{'name'} . "\n";
}

END_SCRIPT
