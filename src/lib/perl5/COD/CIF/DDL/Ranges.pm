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
    is_in_range
    is_in_range_numeric
    is_in_range_char
);

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
#           'min'   => 0,
#                The minimum range value.
#           'max'   => 10,
#                The maximum range value.
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

    if( !exists $param->{'min'} &&
        !exists $param->{'max'} ) {
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
#           'min' - => 0,
#                The minimum range value.
#           'max'   => 10,
#                The maximum range value.
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

    my $min   = $param->{'min'};
    my $max   = $param->{'max'};
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
#           'min' - => a,
#                The minimum range value.
#           'max'   => c,
#                The maximum range value.
#         }
# @return
#        0 if the value is out of the provided range;
#        1 if the value is in the provided range.
##
sub is_in_range_char
{
    my ( $value, $param ) = @_;

    if(
        ( !exists $param->{max} || $value le $param->{max} )
        &&
        ( !exists $param->{min} || $value ge $param->{min} )
    ) {
        return 1;
    }
    return 0;
}
