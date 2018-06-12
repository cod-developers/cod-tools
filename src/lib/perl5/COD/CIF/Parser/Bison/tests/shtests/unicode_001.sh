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
$Data::Dumper::Indent   = 1;
use COD::CIF::Parser::Bison;

my $script_dir  = File::Basename::dirname( $0 );
my $script_name = File::Basename::basename( $0 );

$script_name =~ s/[.]sh$//;

my $filename = "${script_dir}/${script_name}.inp";
my $parser = COD::CIF::Parser::Bison->new();
my ($data) = $parser->Run( $filename, {} );

print Dumper($data);
