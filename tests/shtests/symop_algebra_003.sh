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
#  Unit-test the Spacegroups::Symop::Algebra module
#**

use strict;
use warnings;

use COD::Spacegroups::Symop::Algebra qw( symop_translate
                                         symop_mul
                                         symop_vector_mul ) ;
use COD::Spacegroups::Symop::Parse qw( symop_print );

sub vector_print
{
    local $, = " ";
    local $\ = "\n";
    print @_;
}

sub print_symop_application_result
{
    my ($symop, $vector ) = @_;

    symop_print( $symop );
    print "\n";
    vector_print( @$vector );
    print "\n";

    my $result = symop_vector_mul( $symop, $vector );

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
