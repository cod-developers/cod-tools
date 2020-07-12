#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------

INPUT_MODULE=src/lib/perl5/COD/CIF/Parser/Bison.pm
INPUT_CIF=tests/inputs/cif_parse/missing-closing-double-quote.cif

#END DEPEND--------------------------------------------------------------------

perl <<"END_SCRIPT"
use strict;
use warnings;
use COD::CIF::Parser::Bison;

my $parser = new COD::CIF::Parser::Bison;
$parser->Run( "tests/inputs/cif_parse/missing-closing-double-quote.cif",
              { fix_errors => 0 } );
END_SCRIPT
