#! /bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl -x $0 ${1+"$@"}'
    if 0;
#------------------------------------------------------------------------------
#$Author: saulius $
#$Date: 2007-12-14 09:50:59 +0000 (Fri, 14 Dec 2007) $ 
#$Revision: 250 $
#$URL: svn+ssh://pitonas.ibt.lt/home/xray/svn-repositories/cif-tools/trunk/CIFParser/shtests/text_field_001.sh $
#------------------------------------------------------------------------------
#*
#  Perl test driver.
#**

use strict;

use lib ".";
use lib "lib/perl5";
use lib "CIFParser";

use File::Basename;
use CIFParser;
use ShowStruct;

my $script_dir  = File::Basename::dirname( $0 );
my $script_name = File::Basename::basename( $0 );

$script_name =~ s/\.sh$//;

my $filename = "${script_dir}/${script_name}.inp";

my $parser = new CIFParser;

my $data = $parser->Run($filename);

showRef($data);

while(my($k,$v) = each %{$data->[0]{values}}) {
    print "Values for '$k':\n";
    for my $mas(@{$v}) {
        print $mas . "\n";
    }
    print "-" x 20 . "\n";
}

exit 0;
