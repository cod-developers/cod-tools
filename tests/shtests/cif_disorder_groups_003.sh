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

# One disorder assembly with 3 disorder groups of different occupancies.
# In addition, there are atoms 'N1' and 'N2' which do not belong to any
# disorder group.
my $atoms =
[
    {
        'site_label'=>'A1',
        'name'=>'A1',
        'assembly'=>'A',
        'group'=>'1',
        'atom_site_occupancy'=>'0.1'
    },
    {
        'site_label'=>'A2',
        'name'=>'A2',
        'assembly'=>'A',
        'group'=>'2',
        'atom_site_occupancy'=>'0.7'
    },
    {
        'site_label'=>'A3',
        'name'=>'A3',
        'assembly'=>'A',
        'group'=>'3',
        'atom_site_occupancy'=>'0.2'
    },

    {
        'site_label'=>'N1',
        'name'=>'N1',
        'assembly'=>'.',
        'group'=>'.',
        'atom_site_occupancy'=>'.'
    },
    {
        'site_label'=>'N2',
        'name'=>'N2',
        'assembly'=>'.',
        'group'=>'.',
        'atom_site_occupancy'=>'.'
    }
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
