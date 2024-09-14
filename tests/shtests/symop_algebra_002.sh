#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_SYMOP_ALGEBRA_MODULE=src/lib/perl5/COD/Spacegroups/Symop/Algebra.pm
INPUT_SYMOP_PARSE_MODULE=src/lib/perl5/COD/Spacegroups/Symop/Parse.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_SYMOP_ALGEBRA_MODULE=$(\
    echo ${INPUT_SYMOP_ALGEBRA_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

IMPORT_SYMOP_PARSE_MODULE=$(\
    echo ${INPUT_SYMOP_PARSE_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_SYMOP_ALGEBRA_MODULE} qw( symop_invert )" \
     -M"${IMPORT_SYMOP_PARSE_MODULE}   qw( symop_print )" \
<<'END_SCRIPT'
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

# use COD::Spacegroups::Symop::Algebra qw( symop_invert );
# use COD::Spacegroups::Symop::Parse qw( symop_print );

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

END_SCRIPT
