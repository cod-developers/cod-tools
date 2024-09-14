#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/AuthorNames.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( canonicalize_author_name )" \
<<'END_SCRIPT'
use strict;
use warnings;

# use COD::AuthorNames qw( canonicalize_author_name );

my @names = (
    'Name A. Surname',
    'Surname, Name A.',
    'Surname, Name A.B.',
    'Surname, Name A. B.',
    'Surname, A. B.',
    'Surname, A.B.',
    'Surname, A B',
    'von Surname, Jr, Name',
    'Name Surname II',
);

for (@names) {
    print canonicalize_author_name( $_, 1 ), "\n";
}
END_SCRIPT
