#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/AuthorNames.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::AuthorNames::author_names_are_the_same()
#* subroutine. Tests the way the subroutine handles situations when both
#* timestamp values are undefined.
#**

use strict;
use warnings;
use utf8;

use COD::AuthorNames qw( author_names_are_the_same );

my @names = (
    [ 'John Doe', 'Doe, John', '  John   Doe  ' ],
    [ 'A. B. Doe', 'Doe, A. B.', 'A B Doe', 'Adam Bob Doe', 'Doe, B. Adam' ],
    [ 'Sąžininga Žąsis', 'Zasis, Sazininga' ]
);

for my $test (@names) {
    for my $i (0..$#$test) {
        for my $j ($i..$#$test) {
            next if author_names_are_the_same( $test->[$i], $test->[$j],
                                               { names_to_initials => 1,
                                                 transliterate_non_ascii => 1 } );
            print "'$test->[$i]' and '$test->[$j]' are not the same\n";
        }
    }
}

END_SCRIPT
