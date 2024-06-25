#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/Check.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( check_unquoted_strings )" \
<<'END_SCRIPT'
#**
#* Unit test for the COD::CIF::Data::Check::check_unquoted_strings() subroutine.
#* Tests the way the data items that contain the "_atom_" substring in their name
#* are treated. Values of such data items that contain trailing single quote
#* symbols should be silently ignored.
#**

use strict;
use warnings;

use COD::CIF::Data::Check qw( check_unquoted_strings );

##
# The $data_block structure represents the following CIF file:
# data_test
# loop_
# _atom_site_label                      C4' C7; C8 ;C9
# loop_
# _data_point_label                     C4' C7; C8 ;C9
# _atom_sites_special_details           Unknown;
# _atom_type.description                Carbon'
##

my $data_block =
{
    'cifversion' => {
        'major' => 1,
        'minor' => 1
    },
    'inloop' => {
        '_atom_site_label' => 0,
        '_data_point_label' => 1
    },
    'loops' => [
        [
            '_atom_site_label'
        ],
        [
            '_data_point_label'
        ]
    ],
    'name' => 'test',
    'precisions' => {},
    'save_blocks' => [],
    'tags' => [
        '_atom_site_label',
        '_data_point_label',
        '_atom_sites_special_details',
        '_atom_type.description'
    ],
    'types' => {
        '_atom_site_label' => [
            'UQSTRING',
            'UQSTRING',
            'UQSTRING',
            'UQSTRING'
        ],
        '_atom_sites_special_details' => [
            'UQSTRING'
        ],
        '_atom_type.description' => [
            'UQSTRING'
        ],
        '_data_point_label' => [
            'UQSTRING',
            'UQSTRING',
            'UQSTRING',
            'UQSTRING'
        ]
    },
    'values' => {
        '_atom_site_label' => [
            'C4\'',
            'C7;',
            'C8',
            ';C9'
        ],
        '_atom_sites_special_details' => [
            'Unknown;'
        ],
        '_atom_type.description' => [
            'Carbon\''
        ],
        '_data_point_label' => [
            'C4\'',
            'C7;',
            'C8',
            ';C9'
        ]
    }
};

my $messages = COD::CIF::Data::Check::check_unquoted_strings( $data_block );

if (@{$messages}) {
    for (@{$messages}) {
        print "$_\n";
    }
} else {
    print "No audit messages returned.\n";
}

END_SCRIPT
