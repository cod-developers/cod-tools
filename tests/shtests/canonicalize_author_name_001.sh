#!/usr/bin/perl

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
);

for (@names) {
    print canonicalize_author_name( $_, 1 ), "\n";
}
