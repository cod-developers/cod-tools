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

perl -M"${IMPORT_SYMOP_ALGEBRA_MODULE} qw( symop_vector_mul )" \
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

# use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul ) ;
# use COD::Spacegroups::Symop::Parse qw( symop_print );

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

END_SCRIPT
