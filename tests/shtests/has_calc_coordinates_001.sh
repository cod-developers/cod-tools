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

my $empty  = new_datablock( 'empty' );

my $normal_good = new_datablock( 'normal_good' );
$normal_good->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'd', 'c' ] ;
$normal_good->{values}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ] ;

my $normal_bad = new_datablock( 'normal_bad' );
$normal_bad->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'c', 'calc' ] ;
$normal_bad->{values}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ] ;

my $no_flags = new_datablock( 'no_flags' );
$no_flags->{values}{'_atom_site_label'} = [ 'C1', 'C2', 'C3', 'C4', 'H1' ] ;

my $no_labels = new_datablock( 'no_labels' );
$no_labels->{values}{'_atom_site_calc_flag'} = [ 'd', 'd', 'd', 'c', 'c' ] ;

for ($empty, $normal_good, $normal_bad, $no_flags, $no_labels) {
    if (has_calc_coordinates($_)) {
        print 'Data block \'' . $_->{'name'} . '\' has heavy atoms with calculated coordinates.' . "\n";
    } else {
        print 'Data block \'' . $_->{'name'} . '\' does not have heavy atoms with calculated coordinates.' . "\n";
    }
}

END_SCRIPT
