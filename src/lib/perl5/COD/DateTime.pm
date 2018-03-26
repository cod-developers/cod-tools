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
use DateTime::Format::RFC3339;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    parse_datetime
    is_date_only_timestamp
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

    return ( $timestamp =~ /^\d{4}-\d{2}-\d{2}$/ ) ? 1 : 0;
}

##
# Parses the datetime string and returns a DateTime object. The accepted
# datetime strings can be expressed either as a date only time (YYYY-MM-DD)
# or a datetime value (as defined in RFC3339). In case a non-conforming string
# is passed the subroutine dies.
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
        if ( $datetime_string =~ /^(\d{4})-(\d{2})-(\d{2})$/ ) {
            $datetime = DateTime->new(
                            'year'  => $1,
                            'month' => $2,
                            'day'   => $3,
                        );
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

1;
