#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/CIF/Data/AtomList.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::CIF::Data::AtomList::is_atom_excludable subroutine.
#**

use strict;
use warnings;

use COD::CIF::Data::AtomList;

my $values_1 =
{
    _atom_site_label => [ 'H', 'h', 'HO', 'Ho', 'H1', 'h1' ],
};

my $values_2 =
{
    _atom_site_label       => [ 'H',  'h', 'HO', 'Ho', 'H1', 'h1' ],
    _atom_site_type_symbol => [ 'He', 'D', 'H',  'h',  '?',  '?'  ],
};

for my $values ($values_1, $values_2) {
    for my $i (0..$#{$values->{_atom_site_label}}) {
        print "\t" if $i;
        print COD::CIF::Data::AtomList::is_atom_excludable( $values,
                                                            $i,
                                                            { is_hydrogen => 1 } )
              ? 'YES' : 'NO';
    }
    print "\n";
}

END_SCRIPT
