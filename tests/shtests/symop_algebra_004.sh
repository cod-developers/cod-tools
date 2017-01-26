#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/Spacegroups/Symop/Algebra.pm \
               src/lib/perl5/COD/Spacegroups/Symop/Parse.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
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

use COD::Spacegroups::Symop::Algebra qw( symop_translate symop_mul );
use COD::Spacegroups::Symop::Parse qw( symop_print );

sub vector_print
{
    local $, = " ";
    local $\ = "\n";
    print @_;
}

sub print_symop_translation
{
    my ($symop, $vector) = @_;

    symop_print( $symop );
    print "\n";
    vector_print( @$vector );
    print "\n";

    my $result = symop_translate( $symop, $vector );

    symop_print( $result );
    print "=" x 79, "\n";
}

print_symop_translation(
    [[ 1, 0, 0, 0 ],
     [ 0,-1, 0, 0 ],
     [ 0, 0,-1, 0 ],
     [ 0, 0, 0, 1 ]],

    [ 1, 2, 3 ]
);

print_symop_translation(
    [[ 1, 0, 0, 0 ],
     [ 0,-1, 0, 0 ],
     [ 0, 0,-1, 0 ],
     [ 0, 0, 0, 1 ]],

    [ 1, 2, 3, 1 ]
);

print_symop_translation(
    [[ 1, 0, 0, 3 ],
     [ 0,-1, 0, 2 ],
     [ 0, 0,-1, 1 ],
     [ 0, 0, 0, 1 ]],

    [ 1, 2, 3 ]
);

print_symop_translation(
    [[ 1, 0, 0, 3 ],
     [ 0,-1, 0, 2 ],
     [ 0, 0,-1, 1 ],
     [ 0, 0, 0, 1 ]],

    [ 1, 2, 3, 1 ]
);

END_SCRIPT
