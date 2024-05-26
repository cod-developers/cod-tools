#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/AuthorNames.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( author_names_are_the_same )" \
<<'END_SCRIPT'
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

# use COD::AuthorNames qw( author_names_are_the_same );

binmode( STDOUT, 'utf8' );
binmode( STDERR, 'utf8' );

my @names = (
    [ 'John Doe', 'Doe, John', '  John   Doe  ' ],
    [ 'A. B. Doe', 'Doe, A. B.', 'A B Doe', 'Adam Bob Doe', 'Doe, Adam B.' ],
    [ 'Sąžininga Žąsis', 'Zasis, Sazininga' ]
);

print "Without any options\n";

for my $test (@names) {
    for my $i (0..$#$test) {
        for my $j ($i..$#$test) {
            next if author_names_are_the_same( $test->[$i], $test->[$j] );
            print "\t'$test->[$i]' and '$test->[$j]' are not the same\n";
        }
    }
}

print "Transliterate non-ASCII\n";

for my $test (@names) {
    for my $i (0..$#$test) {
        for my $j ($i..$#$test) {
            next if author_names_are_the_same( $test->[$i], $test->[$j],
                                               { transliterate_non_ascii => 1 } );
            print "\t'$test->[$i]' and '$test->[$j]' are not the same\n";
        }
    }
}

print "Names to initials\n";

for my $test (@names) {
    for my $i (0..$#$test) {
        for my $j ($i..$#$test) {
            next if author_names_are_the_same( $test->[$i], $test->[$j],
                                               { names_to_initials => 1 } );
            print "\t'$test->[$i]' and '$test->[$j]' are not the same\n";
        }
    }
}

END_SCRIPT
