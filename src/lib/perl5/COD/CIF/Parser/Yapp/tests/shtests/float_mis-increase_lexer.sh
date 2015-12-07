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

while(my($k,$v) = each(%{$data->[0]{inloop}})) {
    print "Tag '" . $k . "' is in loop.\n";
}

for my $tag (@{$data->[0]{tags}}) {
    print "Tag '" . $tag . "' values:\n";
    for my $value(@{$data->[0]{values}{$tag}}) {
        print '>> ' . $value . "\n";
    }
    print "-" x 15 . "\n";
}
