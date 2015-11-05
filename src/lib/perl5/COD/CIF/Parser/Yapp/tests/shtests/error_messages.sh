#! /bin/sh
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
#  Perl test driver for testing the way error messages are handled (printed out
#  to STDERR or stored in an array).
#**

use strict;
use warnings;

use File::Basename;
use COD::CIF::Parser::Yapp;

my $script_dir  = File::Basename::dirname( $0 );
my $script_name = File::Basename::basename( $0 );

$script_name =~ s/\.sh$//;

my $filename = "${script_dir}/${script_name}.inp";

my $parser = new COD::CIF::Parser::Yapp;
my $data = $parser->Run($filename, { fix_errors => 1, no_print => 1 } );

foreach(@{$parser->YYData->{ERROR_MESSAGES}}) {
    print $_;
}

for my $tag (@{$data->[0]{tags}}) {
    for my $value (@{$data->[0]{values}{$tag}}) {
        print ">> $tag $value \n";
    }

}
