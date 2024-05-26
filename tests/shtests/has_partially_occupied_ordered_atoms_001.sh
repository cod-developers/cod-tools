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

perl -M"${IMPORT_FLAGS_MODULE}  qw( has_partially_occupied_ordered_atoms )" \
     -M"${IMPORT_MANAGE_MODULE} qw( exclude_tag new_datablock set_loop_tag )" \
<<'END_SCRIPT'
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

my $with_su = clone( $with_partials );
$with_su->{name} = 'without_occupancies_with_su';
$with_su->{values}{_atom_site_occupancy}[2] = '1(0)';
$with_su->{values}{_atom_site_occupancy}[3] = '0.50(5)';

foreach ($empty, $with_partials, $without_occupancies, $with_su) {
    if (has_partially_occupied_ordered_atoms($_)) {
        print 'Data block \'' . $_->{'name'} . '\' has partially occupied ordered atoms.' . "\n";
    } else {
        print 'Data block \'' . $_->{'name'} . '\' does not have partially occupied ordered atoms.' . "\n";
    }
}

END_SCRIPT
