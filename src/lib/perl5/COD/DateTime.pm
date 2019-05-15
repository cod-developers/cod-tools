#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Parses and handles DateTime values.
#**

package COD::DateTime;

use strict;
use warnings;
use Date::Calc qw( check_date );
use DateTime::Format::RFC3339;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    parse_date
    parse_datetime
    is_date_only_timestamp
    canonicalise_timestamp
);

##
# Evaluates if the given string conforms to the YYYY-MM-DD date only time format.
#
# @param $timestamp
#       String that should be checked.
# @return
#       1 if the string conforms to the date only time format, 0 otherwise.
##
sub is_date_only_timestamp
{
    my ($timestamp) = @_;

    return ( $timestamp =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ ) ? 1 : 0;
}

##
# Parses a date string and returns a DateTime object. The accepted date strings
# must be expressed as ISO standard dates of the form <yyyy>-<mm>-<dd>. The
# subroutine dies upon encountering an invalid date string.
#
# @param $date_string
#       Date string that should be parsed.
# @return
#       A DateTime object corresponding to the parsed string.
##
sub parse_date
{
    my ($date_string) = @_;

    my $datetime;
    if ( is_date_only_timestamp( $date_string ) &&
         $date_string =~ m/^([0-9]{4})-([0-9]{2})-([0-9]{2})$/ &&
         check_date( $1, $2, $3 ) ) {
        $datetime = DateTime->new(
                        'year'  => $1,
                        'month' => $2,
                        'day'   => $3,
                    );
    } else {
        die "ERROR, value '$date_string' could not be succesfully parsed as " .
            'an ISO standard date of the form <yyyy>-<mm>-<dd>';
    }

    return $datetime;
}

##
# Parses a datetime string and returns a DateTime object. The accepted
# datetime strings must be expressed either as a date only time (YYYY-MM-DD)
# or a datetime value (as defined in RFC3339). The subroutine dies upon
# encountering an invalid date string.
#
# @param $datetime_string
#       Datetime string that should be parsed.
# @return
#       A DateTime object corresponding to the parsed string.
##
sub parse_datetime
{
    my ($datetime_string) = @_;

    my $datetime;
    eval {
        # Parse date only time
        if ( is_date_only_timestamp( $datetime_string ) ) {
            $datetime = parse_date($datetime_string);
        } else {
            my $parser = DateTime::Format::RFC3339->new();
            $datetime = $parser->parse_datetime($datetime_string);
        }
    };
    if ($@) {
        die "ERROR, value '$datetime_string' could not be succesfully " .
            'parsed as a timestamp value' . "\n";
    }

    return $datetime;
}

##
# Transforms a timestamp string into the canonical notation.
# Date only strings are not modified in any way.
#
# @param $timestamp
#       Timestamp string that should be canonicalised.
# @return
#       Canonicalised timestamp string.
##
sub canonicalise_timestamp
{
    my ($timestamp) = @_;

    if ( is_date_only_timestamp($timestamp) ) {
        return $timestamp;
    };

    my $dt = parse_datetime($timestamp);
    $dt->set_time_zone('UTC');

    return $dt->datetime;
}

1;
