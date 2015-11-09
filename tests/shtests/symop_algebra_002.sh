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

use COD::Spacegroups::Symop::Algebra qw( symop_translate symop_mul symop_invert );
use COD::Spacegroups::Symop::Parse qw( symop_print );

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
