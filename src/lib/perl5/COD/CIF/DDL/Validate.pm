#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* A set of subroutines used to validate CIF files against ontologies expressed
#* in Dictionary Definition Language (DDL).
#**

package COD::CIF::DDL::Validate;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    check_enumeration_set
);

##
# Checks if values belong to the given enumeration set.
# @param $values
#       Reference to an array of values to be checked.
# @param $enum_set
#       Reference to an array of allowed data values.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Ignore the case while matching enumerators
#           'ignore_case'  => 0
#       # Treat data values as potentially consisting of a
#       # combination of several enumeration values
#           'treat_as_set' => 0
#       }
# @return
#       Array reference to a list of boolean states denoting is the
#       values belong to the enumeration set.
##
sub check_enumeration_set
{
    my ($values, $enum_set, $options) = @_;

    my $enum_regex = build_enum_regex( $enum_set, $options );
    my @is_proper_enum = map { $_ !~ m/$enum_regex/s } @{$values};

    return \@is_proper_enum;
}

##
# Constructs a regular expression that matches strings consisting only
# of the given enumeration values.
# @param $enum_set
#       Reference to an array of allowed enumeration values.
# @param $options
#       Reference to a hash of options. The following options are recognised:
#       {
#       # Ignore the case while matching enumerators
#           'ignore_case'  => 0
#       # Treat data values as potentially consisting of a
#       # combination of several enumeration values
#           'treat_as_set' => 0
#       }
# @return $regex
#       String containing the regular expression.
##
sub build_enum_regex
{
    my ($enum_set, $options) = @_;

    my $ignore_case  = defined $options->{'ignore_case'} ?
                               $options->{'ignore_case'} : 0;
    my $treat_as_set = defined $options->{'treat_as_set'} ?
                               $options->{'treat_as_set'} : 0;

    my $values = join '|', map { quotemeta } grep { $_ ne '.' } @{$enum_set};

    my $case_modifier = $ignore_case  ? '(?i)' : '';
    my $set_modifier  = $treat_as_set ? '+'    : '';

    my $regex = qr/^${case_modifier}(?:${values})${set_modifier}$/;

    return $regex;
}

1;
