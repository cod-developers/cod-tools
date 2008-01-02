#! /bin/sh
#!perl -w # --*- Perl -*--
eval 'exec perl5 -x $0 ${1+"$@"}'
    if 0;
#------------------------------------------------------------------------------
#$Author:$
#$Date:$ 
#$Revision:$
#$URL:$
#------------------------------------------------------------------------------
#*
#  Perl script ...
#**

use strict;

local $\ = "\n";
local $, = "||";

while(<>) {
    chomp;
    my @tokens =
	split( /(\s+)/, $_ );
    
    print ">>>", @tokens, "<<<";
}
