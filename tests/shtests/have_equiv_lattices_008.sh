#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/CODNumbers.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE}" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODNumbers::are_equiv_lattices()
#* subroutine. Tests the way the subroutine behaves when both of the
#* lattices are missing some of the length and angle values. Since
#* missing values are treated as being equal to any other value the
#* lattices should be treated as equivalent.
#**

use strict;
use warnings;

# use COD::CIF::Data::CODNumbers;

my $entry_1 = {
    'cell' => {
        '_cell_length_a'    => 5,
        '_cell_length_b'    => undef,
        '_cell_length_c'    => undef,
        '_cell_angle_alpha' => 90,
        '_cell_angle_beta'  => undef,
        '_cell_angle_gamma' => undef,
    },
    'sigcell' => {
        '_cell_length_a'    => undef,
        '_cell_length_b'    => undef,
        '_cell_length_c'    => undef,
        '_cell_angle_alpha' => undef,
        '_cell_angle_beta'  => undef,
        '_cell_angle_gamma' => undef,
    },
};

my $entry_2 = {
    'cell' => {
        '_cell_length_a'    => undef,
        '_cell_length_b'    => 5,
        '_cell_length_c'    => undef,
        '_cell_angle_alpha' => undef,
        '_cell_angle_beta'  => 90,
        '_cell_angle_gamma' => undef,
    },
    'sigcell' => {
        '_cell_length_a'    => undef,
        '_cell_length_b'    => undef,
        '_cell_length_c'    => undef,
        '_cell_angle_alpha' => undef,
        '_cell_angle_beta'  => undef,
        '_cell_angle_gamma' => undef,
    },
};

my $equivalent = COD::CIF::Data::CODNumbers::have_equiv_lattices(
    $entry_1,
    $entry_2,
);

if ( $equivalent ) {
    print "Lattices were treated as equivalent.\n";
} else {
    print "Lattices were treated as not equivalent.\n";
}

END_SCRIPT
