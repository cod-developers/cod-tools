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

use COD::Spacegroups::Symop::Algebra qw(symop_translate symop_mul);
use COD::Spacegroups::Symop::Parse;

sub print_symop_product
{
    my ($symop1, $symop2 ) = @_;

    symop_print( $symop1 );
    print "\n";
    symop_print( $symop2 );
    print "\n";

    my $symop3 = symop_mul( $symop1, $symop2 );

    symop_print( $symop3 );
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
