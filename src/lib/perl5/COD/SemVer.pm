#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Parses, compares and builds Semantic Version (SemVer) 2.0.0 version strings
#* (https://semver.org/spec/v2.0.0.html).
#**

package COD::SemVer;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    build_version_string
    compare_versions
    parse_version_string
);

##
# Parses a SemVer 2.0.0 string [1] using the regular expression [2] adapted
# from the original specification.
#
# @source [1]
#       https://semver.org/spec/v2.0.0.html
# @source [2]
#       https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
#
# @param $version_string
#       SemVer string that should be parsed.
# @return
#       Reference to a data structure of the following form:
#       {
#         # Major version number.
#           'major' => 4,
#         # Minor version number.
#           'minor' => 3,
#         # Patch version number.
#           'patch' => 2
#         # Pre-release identifiers captured as single string.
#         # May be undefined.
#           'pre_release' => 'dev-0.pre-7'
#         # Build metadata identifiers captured as single string.
#         # May be undefined.
#           'build' => 'build-2000-01-01'
#       }
#
#       or undef value if the version string could not be parsed.
##
sub parse_version_string
{
    my ($version_string) = @_;

    my $version_components;
    if ($version_string =~
                m/^(0|[1-9][0-9]*)[.] # MAJOR
                   (0|[1-9][0-9]*)[.] # MINOR
                   (0|[1-9][0-9]*)    # PATCH
                   (?:-(
                       (?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)
                       (?:[.](?:0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*
                   ))?
                   (?:[+]([0-9a-zA-Z-]+(?:[.][0-9a-zA-Z-]+)*))?$/x) {
        $version_components = { 'major' => $1,
                                'minor' => $2,
                                'patch' => $3,
                                'pre_release' => $4,
                                'build_metadata' => $5 };
    }

    return $version_components;
}

##
# Construct a version string from individual version components.
#
# @param $version
#       Data structure that contains the version components as
#       returned by the parse_version_string() subroutine.
# @return $version_string
#       Constructed version string.
##
sub build_version_string
{
    my ($version) = @_;

    my $version_string = join '.', map { $version->{$_} } qw(major minor patch);
    if (defined $version->{'pre_release'}) {
        $version_string .= '-' . $version->{'pre_release'};
    }
    if (defined $version->{'build_metadata'}) {
        $version_string .= '+' . $version->{'build_metadata'};
    }

    return $version_string;
}

##
# Compares two parsed DDLm version numbers as if they were SemVer 2.0 [1]
# strings.
#
# @source [1]
#       https://semver.org/spec/v2.0.0.html
#
# @param $version_a
#       Data structure of the first parsed version number as
#       returned by the parse_version_string() subroutine.
# @param $version_b
#       Data structure of the second parsed version number as
#       returned by the parse_version_string() subroutine.
# @return
#        1 if $version_a > $version_b
#        0 if $version_a = $version_b
#       -1 if $version_a < $version_b
##
sub compare_versions
{
    my ($version_a, $version_b) = @_;

    ## no critic (ProhibitMagicNumbers)
    return -1 if ($version_a->{'major'} < $version_b->{'major'});
    return  1 if ($version_a->{'major'} > $version_b->{'major'});
    return -1 if ($version_a->{'minor'} < $version_b->{'minor'});
    return  1 if ($version_a->{'minor'} > $version_b->{'minor'});
    return -1 if ($version_a->{'patch'} < $version_b->{'patch'});
    return  1 if ($version_a->{'patch'} > $version_b->{'patch'});

    # When major, minor, and patch are equal, a pre-release version has
    # lower precedence than a normal version.
    if (!defined $version_a->{'pre_release'}) {
        return ( !defined $version_b->{'pre_release'} ? 0 : 1 );
    } else {
        return -1 if !defined $version_b->{'pre_release'};
    }

    ##
    # Precedence for two pre-release versions with the same major, minor,
    # and patch version MUST be determined by comparing each dot separated
    # identifier from left to right until a difference is found as follows:
    #
    # 1. Identifiers consisting of only digits are compared numerically.
    # 2. Identifiers with letters or hyphens are compared lexically in ASCII
    #    sort order.
    # 3. Numeric identifiers always have lower precedence than non-numeric
    #    identifiers.
    # 4. A larger set of pre-release fields has a higher precedence than a
    #    smaller set, if all of the preceding identifiers are equal.
    #
    # @source [2]
    #       https://semver.org/#spec-item-11
    ##
    my @pre_release_ids_a = split /[.]/, $version_a->{'pre_release'};
    my @pre_release_ids_b = split /[.]/, $version_b->{'pre_release'};
    for my $i (0..$#pre_release_ids_a) {
        return 1 if $i > $#pre_release_ids_b;
        my $is_a_id_numeric = $pre_release_ids_a[$i] =~ /^[1-9][0-9]*$/;
        my $is_b_id_numeric = $pre_release_ids_b[$i] =~ /^[1-9][0-9]*$/;
        if ( $is_a_id_numeric && $is_b_id_numeric &&
             $pre_release_ids_a[$i] != $pre_release_ids_b[$i] ) {
            return $pre_release_ids_a[$i] <=> $pre_release_ids_b[$i];
        }
        if ( !$is_a_id_numeric && !$is_b_id_numeric &&
             $pre_release_ids_a[$i] ne $pre_release_ids_b[$i] ) {
            return $pre_release_ids_a[$i] cmp $pre_release_ids_b[$i]
        }
        if ( $is_a_id_numeric && !$is_b_id_numeric ) {
            return -1;
        }
        if ( !$is_a_id_numeric && $is_b_id_numeric ) {
            return 1;
        }
    }
    return -1 if @pre_release_ids_b > @pre_release_ids_a;
    ## use critic

    return 0;
}

1;
