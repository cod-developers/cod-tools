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

sub print_symop_product
{
    my ($symop1, $symop2 ) = @_;

    SymopParse::symop_print( $symop1 );
    print "\n";
    SymopParse::symop_print( $symop2 );
    print "\n";

    my $symop3 = SymopAlgebra::symop_mul( $symop1, $symop2 );

    SymopParse::symop_print( $symop3 );
    print "=" x 79, "\n";
}

print_symop_product(
    [[ 1, 0, 0 ],
     [ 0,-1, 0 ],
     [ 0, 0,-1 ]],

    [[-1, 0, 0 ],
     [ 0, 1, 0 ],
     [ 0, 0,-1 ]]
);

print_symop_product(
    [[ 1, 0, 0, 0.5],
     [ 0,-1, 0, 0  ],
     [ 0, 0,-1, 0  ],
     [ 0, 0, 0, 1  ]],

    [[-1, 0, 0, 0  ],
     [ 0, 1, 0, 0.5],
     [ 0, 0,-1, 0  ],
     [ 0, 0, 0, 1  ]]
);
