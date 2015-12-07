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
#  Perl test driver.
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

my $data = $parser->Run($filename);

for my $h (@{$data->[0]{save_blocks}}) {
    print "SAVE_ block\n";
    while(my($k,$v) = each %{$h}) {
        next unless $k eq "values";
        print "Keys:\n\to) ";
        local $, = "\n\to) ";
        print sort keys %{$v};
        print "\n";
    }
    print "\n";
}

exit 0;
