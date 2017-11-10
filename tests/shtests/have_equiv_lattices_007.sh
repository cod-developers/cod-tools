#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/CODNumbers.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::CODNumbers::are_equiv_lattices()
#* subroutine. Tests the way the subroutine behaves when two lattices
#* with differing cell parameters are compared. In this case the s.u.
#* values are not provided and the 'max_cell_length_diff' and
#* 'max_cell_angle_diff' options are given explicit values. The lattices
#* should be considered not equivalent.
#**

use strict;
use warnings;

use COD::CIF::Data::CODNumbers;

my $entry_1 = {
    'cell' => {
        '_cell_length_a'    => 5,
        '_cell_length_b'    => 5,
        '_cell_length_c'    => 5,
        '_cell_angle_alpha' => 90,
        '_cell_angle_beta'  => 90,
        '_cell_angle_gamma' => 90,
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
        '_cell_length_a'    => 4.5,
        '_cell_length_b'    => 5,
        '_cell_length_c'    => 5,
        '_cell_angle_alpha' => 85,
        '_cell_angle_beta'  => 90,
        '_cell_angle_gamma' => 90,
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
    {
        'max_cell_length_diff' => '0.1',
        'max_cell_angle_diff'  => '1',
    }
);

if ( $equivalent ) {
    print "Lattices were treated as equivalent.\n";
} else {
    print "Lattices were treated as not equivalent.\n";
}

END_SCRIPT
