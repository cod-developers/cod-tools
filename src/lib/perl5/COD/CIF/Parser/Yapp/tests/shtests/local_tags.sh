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

my $data;
eval {
    $data = $parser->Run($filename);
};

print STDERR $@ if $@;

if (!defined $data) {
    print "Unable to parse the CIF file.\n";
}

while(my($k,$v) = each %{$data->[0]{values}}) {
    print "Values for '$k':\n";
    for my $mas(@{$v}) {
        print $mas . "\n";
    }
    print "-" x 20 . "\n";
}

exit 0;
