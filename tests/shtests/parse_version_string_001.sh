#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/SemVer.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( parse_version_string )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
# $Author$
# $Date$
# $Revision$
# $URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::SemVer::parse_version_string() subroutine. Tests the
#* way the subroutine handles valid and invalid version strings.
#**

use strict;
use warnings;

use COD::SemVer qw( parse_version_string );

#
# Valid and invalid test values copied from the official regex test suite:
# https://regex101.com/r/Ly7O1x/3/
# 
my @valid_version_strings = qw(
    0.0.4
    1.2.3
    10.20.30
    1.0.0-alpha
    1.1.2-prerelease+meta
    1.1.2+meta


    1.0.0-beta
    1.0.0-alpha.beta
    1.0.0-alpha.beta.1
    1.0.0-alpha.1
    1.0.0-alpha0.valid
    1.0.0-alpha.0valid
    1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay
    1.0.0-rc.1+build.1
    2.0.0-rc.1+build.123
    1.2.3-beta
    10.2.3-DEV-SNAPSHOT
    1.2.3-SNAPSHOT-123
    1.0.0
    2.0.0
    1.1.7
    2.0.0+build.1848
    2.0.1-alpha.1227
    1.0.0-alpha+beta
    1.2.3----RC-SNAPSHOT.12.9.1--.12+788
    1.2.3----R-S.12.9.1--.12+meta
    1.2.3----RC-SNAPSHOT.12.9.1--.12
    1.0.0+0.build.1-rc.10000aaa-kk-0.1
    99999999999999999999999.999999999999999999.99999999999999999
    1.0.0-0A.is.legal
);

my @invalid_version_strings = qw(
    1
    1.2
    1.2.3-0123
    1.2.3-0123.0123
    1.1.2+.123
    +invalid
    -invalid
    -invalid+invalid
    -invalid.01
    alpha
    alpha.beta
    alpha.beta.1
    alpha.1
    alpha+beta
    alpha_beta
    alpha.
    alpha..
    beta
    1.0.0-alpha_beta
    -alpha.
    1.0.0-alpha..
    1.0.0-alpha..1
    1.0.0-alpha...1
    1.0.0-alpha....1
    1.0.0-alpha.....1
    1.0.0-alpha......1
    1.0.0-alpha.......1
    01.1.1
    1.01.1
    1.1.01
    1.2
    1.2.3.DEV
    1.2-SNAPSHOT
    1.2.31.2.3----RC-SNAPSHOT.12.09.1--..12+788
    1.2-RC-SNAPSHOT
    -1.0.3-gamma+b7718
    +justmeta
    9.8.7+meta+meta
    9.8.7-whatever+meta+meta
    99999999999999999999999.999999999999999999.99999999999999999----RC-SNAPSHOT.12.09.1--------------------------------..12
);

for my $version_string (@valid_version_strings, @invalid_version_strings) {
    my $parsed_string = parse_version_string( $version_string );

    if (defined $parsed_string) {
        print 'PASS!';
        for my $component_name ( sort keys %{$parsed_string}) {
            if (defined $parsed_string->{$component_name}) {
                print " $component_name: $parsed_string->{$component_name}"
            }
        }
        print "\n";
    } else {
        print "FAIL! $version_string\n";
    }
}

END_SCRIPT
