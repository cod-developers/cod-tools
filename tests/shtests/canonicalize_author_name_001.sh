#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------

INPUT_MODULE=src/lib/perl5/COD/AuthorNames.pm

#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
use strict;
use warnings;
use COD::AuthorNames qw( canonicalize_author_name );

my @names = (
    'Name A. Surname',
    'Surname, Name A.',
    'Surname, Name A.B.',
    'Surname, Name A. B.',
    'Surname, A. B.',
    'Surname, A.B.',
    'Surname, A B',
    'von Surname, Jr, Name',
    'Surname II, Name',
    'Surname II, N.',
    'Surname II, Name A.',
);

for (@names) {
    print canonicalize_author_name( $_, 1 ), "\n";
}
END_SCRIPT
