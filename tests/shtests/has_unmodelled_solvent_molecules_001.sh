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

perl -M"${IMPORT_FLAGS_MODULE}  qw( has_unmodelled_solvent_molecules )" \
     -M"${IMPORT_MANAGE_MODULE} qw( new_datablock )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#* Unit test for the COD::CIF::Data::CODFlags::has_unmodelled_solvent_molecules()
#* subroutine. Test the way the '_platon_squeeze_void_count_electrons'
#* data item is handled.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODFlags qw( has_unmodelled_solvent_molecules );
# use COD::CIF::Tags::Manage qw( new_datablock );

my @data_blocks;
my $data_block;

# Contains no data about unmodelled solvent molecules.
$data_block = new_datablock( '[NO]_empty' );
push @data_blocks, $data_block;

$data_block = new_datablock( '[YES]_0_platon_squeeze_electrons' );
$data_block->{'values'}{'_platon_squeeze_void_count_electrons'} = [ '0' ];
push @data_blocks, $data_block;

$data_block = new_datablock( '[YES]_30_platon_squeeze_electrons' );
$data_block->{'values'}{'_platon_squeeze_void_count_electrons'} = [ '30' ];
push @data_blocks, $data_block;

$data_block = new_datablock( '[YES]_?_platon_squeeze_electrons' );
$data_block->{'values'}{'_platon_squeeze_void_count_electrons'} = [ '?' ];
push @data_blocks, $data_block;

print "Output\tData block name\n";
for my $test_case (@data_blocks) {
    print has_unmodelled_solvent_molecules($test_case) . "\t" . $test_case->{'name'} . "\n";
}

END_SCRIPT
