#! /bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl -x $0 ${1+"$@"}'
    if 0;

use strict;
use warnings;
use COD::CIF::Parser::Bison;

my $parser = new COD::CIF::Parser::Bison;
$parser->Run("tests/inputs/missing-closing-double-quote.cif",
             { fix_errors => 0 });
