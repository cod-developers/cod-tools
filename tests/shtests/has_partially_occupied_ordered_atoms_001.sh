#! /bin/sh

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
#* Unit test for the COD::CIF::Data::CODFlags::is_retracted subroutine.
#* Tests the way the subroutine behaves when the input data block contains
#* issues of the retraction severity.
#**

use strict;
use warnings;

use COD::CIF::Data::CODFlags qw( has_partially_occupied_ordered_atoms );
use COD::CIF::Tags::Manage qw(
    exclude_tag
    new_datablock
    set_loop_tag
);
use Clone qw( clone );

my $empty         = new_datablock( 'empty' );
my $with_partials = new_datablock( 'with_partials' );

set_loop_tag( $with_partials,
              '_atom_site_label',
              '_atom_site_label',
              [ 'C1', 'C2', 'C3', 'C4', 'C5' ] );
set_loop_tag( $with_partials,
              '_atom_site_occupancy',
              '_atom_site_label',
              [ '.', '?', 1, 0.5, 0.5 ] );
set_loop_tag( $with_partials,
              '_atom_site_disorder_assembly',
              '_atom_site_label',
              [ '.', '.', '.', '.', 'A' ] );
set_loop_tag( $with_partials,
              '_atom_site_disorder_group',
              '_atom_site_label',
              [ '.', '.', '.', 1, 2 ] );

my $without_occupancies = clone( $with_partials );
$without_occupancies->{name} = 'without_occupancies';
exclude_tag( $without_occupancies, '_atom_site_occupancy' );

foreach ($empty, $with_partials, $without_occupancies) {
    if (has_partially_occupied_ordered_atoms($_)) {
        print 'Data block \'' . $_->{'name'} . '\' has partially occupied ordered atoms.' . "\n";
    } else {
        print 'Data block \'' . $_->{'name'} . '\' does not have partially occupied ordered atoms.' . "\n";
    }
}

END_SCRIPT
