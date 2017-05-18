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
#  Perl test driver.
#**

use strict;
use warnings;

use File::Basename;
use COD::CIF::Parser::Bison;

my $script_dir  = File::Basename::dirname( $0 );
my $script_name = File::Basename::basename( $0 );

$script_name =~ s/\.sh$//;

my $filename = "${script_dir}/${script_name}.inp";

my ($parser, $data);

print "Unprefix: no\nUnfold: no\n";
$parser = new COD::CIF::Parser::Bison;
$data = $parser->Run( $filename, { 'do_not_unprefix_text' => 1,
                                   'do_not_unfold_text'   => 1 } );
print $data->[0]{values}{_text_field_tag}[0], "\n";

print "\n";
print "Unprefix: yes\nUnfold: no\n";
$parser = new COD::CIF::Parser::Bison;
$data = $parser->Run( $filename, { 'do_not_unprefix_text' => 0,
                                   'do_not_unfold_text'   => 1 } );
print $data->[0]{values}{_text_field_tag}[0], "\n";

print "\n";
print "Unprefix: no\nUnfold: yes\n";
$parser = new COD::CIF::Parser::Bison;
$data = $parser->Run( $filename, { 'do_not_unprefix_text' => 1,
                                   'do_not_unfold_text'   => 0 } );
print $data->[0]{values}{_text_field_tag}[0], "\n";

print "\n";
print "Unprefix: yes\nUnfold: yes\n";
$parser = new COD::CIF::Parser::Bison;
$data = $parser->Run( $filename, { 'do_not_unprefix_text' => 0,
                                   'do_not_unfold_text'   => 0 } );
print $data->[0]{values}{_text_field_tag}[0], "\n";
