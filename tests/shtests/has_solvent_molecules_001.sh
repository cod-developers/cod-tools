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
#* Unit test for the COD::CIF::Data::CODFlags::has_solvent_molecules()
#* subroutine.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_solvent_molecules );
use COD::CIF::Tags::Manage qw( new_datablock );

my $empty  = new_datablock( 'empty' );

my $normal_good = new_datablock( 'normal_good' );
$normal_good->{values}{'_platon_squeeze_void_count_electrons'} = [ '0' ] ;

my $normal_bad = new_datablock( 'normal_bad' );
$normal_bad->{values}{'_platon_squeeze_void_count_electrons'} = [ '30' ] ;

my $value_symbol = new_datablock( 'value_symbol' );
$value_symbol->{values}{'_platon_squeeze_void_count_electrons'} = [ '?' ] ;

my $value_empty = new_datablock( 'value_empty' );
$value_empty->{values}{'_platon_squeeze_void_count_electrons'} = [ ] ;

for ($empty, $normal_good, $normal_bad, $value_symbol, $value_empty) {
    if (has_solvent_molecules($_)) {
        print 'Data block \'' . $_->{'name'} . '\' has not modeled solvent molecules.' . "\n";
    } else {
        print 'Data block \'' . $_->{'name'} . '\' does not have not modeled solvent molecules.' . "\n";
    }
}

END_SCRIPT
