#! /bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULES='src/lib/perl5/COD/SemVer.pm'
#END DEPEND--------------------------------------------------------------------

perl <<'END_SCRIPT'
#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::SemVer::compare_versions() subroutine. Tests the
#* way the subroutine handles valid version strings.
#**

use strict;
use warnings;

use COD::SemVer qw( compare_versions
                    parse_version_string );

my @version_pairs = (
    # Equal
    [ '1.3.14', '1.3.14' ], # 0 ( [1] == [2] )

    # Major
    [ '5.3.14', '1.3.14' ], #  1 ( [1] > [2] )
    [ '1.3.14', '5.3.14' ], # -1 ( [1] < [2] )

    # Minor
    [ '1.7.14', '1.3.14' ], #  1 ( [1] > [2] )
    [ '1.3.14', '1.7.14' ], # -1 ( [1] < [2] )

    # Patch
    [ '1.3.23', '1.3.14' ], #  1 ( [1] > [2] )
    [ '1.3.14', '1.3.23' ], # -1 ( [1] < [2] )

    # Pre-release
    [ '1.3.14',     '1.3.14-pre' ], #  1 ( [1] > [2] )
    [ '1.3.14-pre', '1.3.14'     ], # -1 ( [1] < [2] )

    # Pre-release lexicographical
    [ '1.3.14-pre',  '1.3.14-pre' ],  #  0 ( [1] == [2] )
    [ '1.3.14-alfb', '1.3.14-alfa' ], #  1 ( [1] > [2] )
    [ '1.3.14-alfa', '1.3.14-alfb' ], # -1 ( [1] < [2] )

    # Pre-release numeric
    [ '1.3.14-33', '1.3.14-33' ], #  0 ( [1] == [2] )
    [ '1.3.14-22', '1.3.14-3'  ], #  1 ( [1] > [2] )
    [ '1.3.14-3',  '1.3.14-22' ], # -1 ( [1] < [2] )

    # Pre-release mixed
    [ '1.3.14-1.2.a3.7', '1.3.14-1.2.33.7' ], #  1 ( [1] > [2] )
    [ '1.3.14-1.2.33.7', '1.3.14-1.2.a3.7' ], # -1 ( [1] < [2] )

    # Different number of pre-release components
    [ '1.3.14-1.2.a', '1.3.14-1.2' ], #  1 ( [1] > [2] )
    [ '1.3.14-1.2', '1.3.14-1.2.a' ], # -1 ( [1] < [2] )

);

for my $version_pair (@version_pairs) {
    my $result = compare_versions( parse_version_string( $version_pair->[0] ),
                                   parse_version_string( $version_pair->[1] ) );
    my $operator = '?';
    if ($result == '-1') {
        $operator = '<';
    } elsif ($result == '1') {
        $operator = '>'
    } elsif ($result == '0') {
        $operator = '=';
    }
    printf "%2s: %s %s %s\n", $result, $version_pair->[0], $operator, $version_pair->[1];
}

END_SCRIPT
