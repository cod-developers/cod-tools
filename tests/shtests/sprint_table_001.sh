#!/bin/bash

#BEGIN DEPEND------------------------------------------------------------------

INPUT_MODULE=src/lib/perl5/COD/CIF/Tags/Print.pm

#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
use strict;
use warnings;
use COD::CIF::Tags::Print qw( print_value );

my @table_keys = (
    '',
    '"',
    "'",
    '""',
    "''",
    '"""',
    "'''",
    "'\"",
    "\"'",
    "'''\"",
    '"""\'',
    "\n",
    "\n'",
    "\n\"",
);

foreach (@table_keys) {
    eval {
        print_value( { $_ => 1 }, undef, undef, '2.0' );
        print "\n";
    };
    print $@ if $@;
}
END_SCRIPT
