#!/bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl -x $0 ${1+"$@"}'
    if 0;
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Perl test driver used to check the way precision values are stored.
#**

use strict;
use warnings;

use File::Basename;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use COD::CIF::Parser::Bison;

print Dumper COD::CIF::Parser::Bison::parse_string( "data_test _tag value" );
