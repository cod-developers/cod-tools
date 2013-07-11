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
#  Unit-test the Spacegroups::SymopAlgebra module
#**

use strict;
use warnings;

use Spacegroups::SymopAlgebra;
use Spacegroups::SymopParse;

sub vector_print
{
    local $, = " ";
    local $\ = "\n";
    print @_;
}

sub print_symop_application_result
{
    my ($symop, $vector ) = @_;

    SymopParse::symop_print( $symop );
    print "\n";
    vector_print( @$vector );
    print "\n";

    my $result = SymopAlgebra::symop_apply( $symop, $vector );

    vector_print( @$result );
    print "=" x 79, "\n";
}

print_symop_application_result(
    [[ 1, 0, 0, 0 ],
     [ 0,-1, 0, 0 ],
     [ 0, 0,-1, 0 ],
     [ 0, 0, 0, 1 ]],

    [ 1, 2, 3 ]
);

print_symop_application_result(
    [[ 1, 0, 0, 0 ],
     [ 0,-1, 0, 0 ],
     [ 0, 0,-1, 0 ],
     [ 0, 0, 0, 1 ]],

    [ 1, 2, 3, 1 ]
);

print_symop_application_result(
    [[ 1, 0, 0, 3 ],
     [ 0,-1, 0, 2 ],
     [ 0, 0,-1, 1 ],
     [ 0, 0, 0, 1 ]],

    [ 1, 2, 3 ]
);

print_symop_application_result(
    [[ 1, 0, 0, 3 ],
     [ 0,-1, 0, 2 ],
     [ 0, 0,-1, 1 ],
     [ 0, 0, 0, 1 ]],

    [ 1, 2, 3, 1 ]
);
