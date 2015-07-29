#! /bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl -x $0 ${1+"$@"}'
    if 0;
#------------------------------------------------------------------------------
#$Author: saulius $
#$Date: 2007-12-14 09:32:50 +0000 (Fri, 14 Dec 2007) $ 
#$Revision: 247 $
#$URL: svn+ssh://pitonas.ibt.lt/home/xray/svn-repositories/cif-tools/trunk/CIFParser/shtests/simple.sh $
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

foreach my $datablock (@$data) {
    print $datablock->{name} . "\n";
}

print "Error messages in the returned array:\n";
foreach ( @{$parser->{YYData}->{ERROR_MESSAGES}} ) {
    print $_;
}
