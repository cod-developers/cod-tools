#!/bin/sh

#BEGIN DEPEND------------------------------------------------------------------
INPUT_MODULE=src/lib/perl5/COD/SemVer.pm
#END DEPEND--------------------------------------------------------------------

IMPORT_MODULE=$(\
    echo ${INPUT_MODULE} | \
    perl -pe "s|^src/lib/perl5/||; s/[.]pm$//; s|/|::|g;" \
)

perl -M"${IMPORT_MODULE} qw( build_version_string )" \
<<'END_SCRIPT'
#------------------------------------------------------------------------------
# $Author$
# $Date$
# $Revision$
# $URL$
#------------------------------------------------------------------------------
#*
#* Unit test for the COD::SemVer::build_version_string() subroutine. Tests the
#* way the subroutine handles valid parsed versions.
#**

use strict;
use warnings;

# use COD::SemVer qw( build_version_string );

#
# Valid test values copied from the official regex test suite:
# https://regex101.com/r/Ly7O1x/3/
#
my @parsed_version_strings = (
    # 0.0.4
    {
      'major' => '0',
      'minor' => '0',
      'patch' => '4',
      'pre_release' => undef,
      'build_metadata' => undef
    },
    # 1.2.3
    {
      'major' => '1',
      'minor' => '2',
      'patch' => '3',
      'pre_release' => undef,
      'build_metadata' => undef
    },
    # 10.20.30
    {
      'major' => '10',
      'minor' => '20',
      'patch' => '30',
      'pre_release' => undef,
      'build_metadata' => undef
    },
    # 1.0.0-alpha
    {
      'major' => '1',
      'minor' => '0',
      'patch' => '0',
      'pre_release' => 'alpha',
      'build_metadata' => undef
    },
    # 1.1.2-prerelease+meta
    {
      'patch' => '2',
      'minor' => '1',
      'major' => '1',
      'pre_release' => 'prerelease',
      'build_metadata' => 'meta'
    },
    # 1.1.2+meta
    {
      'major' => '1',
      'minor' => '1',
      'patch' => '2',
      'pre_release' => undef,
      'build_metadata' => 'meta'
    },
);

for my $parsed_version_string (@parsed_version_strings) {
    print build_version_string( $parsed_version_string  ), "\n";
}

END_SCRIPT
