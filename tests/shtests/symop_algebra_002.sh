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

use COD::Spacegroups::SymopAlgebra qw(symop_translate symop_mul symop_invert);
use COD::Spacegroups::SymopParse;

sub print_symop_inverse
{
    my ($symop1) = @_;

    symop_print( $symop1 );
    print "\n";

    my $symop2 = symop_invert( $symop1 );

    symop_print( $symop2 );
    print "=" x 79, "\n";
}

print_symop_inverse(
    [[ 1, 0, 0, 0.5],
     [ 0,-1, 0, 0  ],
     [ 0, 0,-1, 0  ],
     [ 0, 0, 0, 1  ]],
);

print_symop_inverse(
    [[-1, 0, 0, 0  ],
     [ 0, 1, 0, 0.5],
     [ 0, 0,-1, 0  ],
     [ 0, 0, 0, 1  ]]
);

print_symop_inverse(
    [[-1, 0, 0, 0 ],
     [ 0,-1, 0, 0 ],
     [ 0, 0,-1, 0 ],
     [ 0, 0, 0, 1 ]]
);
