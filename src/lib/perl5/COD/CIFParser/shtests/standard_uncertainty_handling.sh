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
#  Perl test driver for testing the way standard uncertainties (s.u.; also 
#  known as e.s.d) are parsed in loop structures. The currently used rule is 
#  as follows:
#  * if any of loop tag values is recognised as a number, all values for that
#    loop are asigned a standard uncertainty value (or 'undef' if no s.u. is 
#    provided). These values are stored in the array, referenced by the 
#    key 'precisions'.
#  * if none of the loop tag values have is recognised as a number, the
#    key 'precisions' is undefined for the corresponding tag.
#**

use strict;

use lib ".";
use lib "lib/perl5";
use lib "CIFParser";

use File::Basename;
use COD::CIFParser::CIFParser;

my $script_dir  = File::Basename::dirname( $0 );
my $script_name = File::Basename::basename( $0 );

$script_name =~ s/\.sh$//;

my $filename = "${script_dir}/${script_name}.inp";

my $parser = new COD::CIFParser::CIFParser;

my $data = $parser->Run($filename);

for my $tag (@{$data->[0]{tags}}) {
    print "Analysing tag '$tag':\n";

    print ">> The following values were found in the loop:\n";
    for my $value(@{$data->[0]{values}{$tag}}) {
        print '>> ' . $value . "\n";
    }

    if (defined $data->[0]{precisions}{$tag}) {
        print ">> Tag '$tag' has a defined 'precisions' field\n";
        for my $value (@{$data->[0]{precisions}{$tag}}) {
            $value = "undef" if !defined $value;
            print '>> ' . $value . "\n";
        }
    } else {
        print ">> Tag '$tag' does not have a defined 'precisions' field\n";
    }

    print "-" x 15 . "\n";
}
