#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/CIF/Data/AtomList.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( atom_groups )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Unit test for the COD::CIF::Data::AtomList module subroutines that deal
#  with the disorder group generation.
#**

use strict;
use warnings;

# use COD::CIF::Data::AtomList qw( atom_groups );

# One disorder assembly with two disorder groups. Disorder group '1' contains
# two atoms with differing occupancies.
my $atoms =
[
    {
        'site_label'=>'A1_1',
        'name'=>'A1_1',
        'assembly'=>'A',
        'group'=>'1',
        'atom_site_occupancy'=>'0.4'
    },
    {
        'site_label'=>'A1_2',
        'name'=>'A1_2',
        'assembly'=>'A',
        'group'=>'1',
        'atom_site_occupancy'=>'0.6'
    },
    {
        'site_label'=>'A11',
        'name'=>'A2_1',
        'assembly'=>'A',
        'group'=>'2',
        'atom_site_occupancy'=>'0.5'
    },
    {
        'site_label'=>'A2_2',
        'name'=>'A2',
        'assembly'=>'A',
        'group'=>'2',
        'atom_site_occupancy'=>'0.5'
    },
];

my $groups = atom_groups($atoms);

my $configuration_no = 0;
for my $group (@{$groups}) {
    $configuration_no++;
    print "Configuration no.: $configuration_no\n";
    for my $atom ( @{$group} ) {
        #print $atom;
        print $atom->{'name'} . " "
            . $atom->{'assembly'} . " "
            . $atom->{'group'} . " "
            . $atom->{'atom_site_occupancy'} . "\n";
    }
}

END_SCRIPT
