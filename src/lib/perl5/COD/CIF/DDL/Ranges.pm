#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* A set of subroutines for handling ranges as defined in the Dictionary
#* Definition Language (DDL) files.
#**

package COD::CIF::DDL::Ranges;

use strict;
use warnings;
use Scalar::Util qw( looks_like_number );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    parse_range
    is_in_range
);

##
# Parse a DDL range string.
#
# @param $range_string
#       String specifying a range as defined in DDL.
# @return $range
#       A reference to an array of two element specifying the range.
#       The first element specifies the lower bound and the second element
#       specifies the upper bound. An undefined element signals that the
#       associated bound is not declared. Either of the elements can be
#       undefined.
##
sub parse_range
{
    my ($range_string) = @_;

    $range_string =~ m/^([^:]+)?:([^:]+)?$/;
    my @range = ($1, $2);

    return \@range;
}

##
# Check value against range (defined in dictionary).
#
# @param $value
#       Value to be checked.
# @param $param
#       Parameter hash with the following keys:
#         {
#           'type'  => 'numb',
#                String, representing the type of value ('numb' or 'char').
#           'range' => [0, 10]
#                Reference to range array as returned by the
#                COD::CIF::DDL::Ranges::parse_range() subroutine.
#           'sigma  => 0.1
#               Standard deviation to be used when comparing numeric values
#               (3 sigma rule). If sigma is not provided, values are compared
#               disregarding the standard deviation.
#         }
# @return
#       -1 if no ranges were provided for the value;
#        0 if the value is out of the provided range;
#        1 if the value is in the provided range.
##
sub is_in_range
{
    my ( $value, $param ) = @_;

    my $range = $param->{'range'};

    if( !defined $range->[0] &&
        !defined $range->[1] ) {
        return -1;
    }

    if( $param->{'type'} eq 'numb' ) {
        return is_in_range_numeric( $value, $param );
    } else {
        return is_in_range_char( $value, $param );
    }
}

##
# Checks numeric value against an inclusive numeric range.
# @param $value
#       Value to be checked.
# @param $param
#       Parameter hash with the following keys:
#         {
#           'range' => [0, 10]
#                Reference to range array as returned by the
#                COD::CIF::DDL::Ranges::parse_range() subroutine.
#           'sigma  => 0.1
#               Standard deviation to be used when comparing numeric values
#               (3 sigma rule). If sigma is not provided, values are compared
#               disregarding the standard deviation.
#         }
# @return
#        0 if the value is out of the provided range or is not a number
#          at all;
#        1 if the value is in the provided range.
##
sub is_in_range_numeric
{
    my ( $value, $param ) = @_;

    my $min   = $param->{'range'}[0];
    my $max   = $param->{'range'}[1];
    my $sigma = $param->{'sigma'};

    if( ! looks_like_number($value) ) {
        return 0;
    }

    if( defined $sigma ) {
        $min = $min - 3 * $sigma if defined $min;
        $max = $max + 3 * $sigma if defined $max;
    };

    if(
        ( !defined $max || $value <= $max )
        &&
        ( !defined $min || $value >= $min )
    ) {
        return 1;
    }
    return 0;
}

##
# Checks character value against an inclusive character range.
# @param $value
#       Value to be checked.
# @param $param
#       Parameter hash with the following keys:
#         {
#           'range' => [a, c]
#                Reference to range array as returned by the
#                COD::CIF::DDL::Ranges::parse_range() subroutine.
#         }
# @return
#        0 if the value is out of the provided range;
#        1 if the value is in the provided range.
##
sub is_in_range_char
{
    my ( $value, $param ) = @_;

    my $range = $param->{'range'};

    if(
        ( !exists $param->[0] || $value ge $range->[0] )
        &&
        ( defined $range->[1] || $value le $range->[1] )
    ) {
        return 1;
    }
    return 0;
}
