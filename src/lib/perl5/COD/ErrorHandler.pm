#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Set of subroutines used to handle error messages in COD perl scripts.
#**

package COD::ErrorHandler;

use strict;
use warnings;
use COD::UserMessage qw( sprint_message parse_message );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    process_warnings
    process_errors
    process_parser_messages
    report_message
);

sub process_parser_messages
{
    my ( $messages, $die_on_error_level, $print_order) = (@_);
    $print_order = [ 'NOTE', 'WARNING', 'ERROR' ] if !defined $print_order;

    my $filename;
    my %err_level_counter;
    foreach ( @$messages ) {
        warn $_;
        my $parsed_message = parse_message($_);
        if ( defined $parsed_message->{err_level} ) {
            $err_level_counter{$parsed_message->{err_level}}++;
        };
        if ( defined $parsed_message->{filename} && !defined $filename ) {
            $filename = $parsed_message->{filename};
        }
    };

    foreach ( @$print_order ) {
        if ( defined $err_level_counter{$_} && $err_level_counter{$_} > 0 ) {
            my $message = sprint_message( {
                'program'   => $0,
                'filename'  => $filename,
                'err_level' => $die_on_error_level->{$_} ? 'ERROR' : 'NOTE',
                'message'   =>
                    "$err_level_counter{$_} $_(s) encountered " .
                    'while parsing the file' . (
                        $die_on_error_level->{$_} ?  " -- die on $_(s) requested"
                                                  : ''
                    )
            } );
            $die_on_error_level->{$_} ? die $message : warn $message;
        }
    };
};

sub report_message
{
    my ( $details, $exit ) = @_;

    print STDERR sprint_message( $details );

    if ( $exit ) {
        my $err_level = $details->{'err_level'};
        print STDERR sprint_message(
            {
                'program'   => $details->{'program'},
                'filename'  => $details->{'filename'},
                'add_pos'   => $details->{'add_pos'},
                'err_level' => 'ERROR',
                'message'   => "1 $err_level(s) encountered -- die on " .
                               "$err_level(s) requested"
            }
        ) ;
        exit 1;
    }
}

sub process_errors
{
    my ( $details, $exit ) = @_;

    my $message = $details->{message};
    # Messages with missing STATUS identifiers probably did not originate in
    # COD modules (for example, system errors) and might start with an
    # uppercase letter
    my $error_level = 'ERROR';
    if ( $message =~ s/^([A-Z]+),\s*// ) {
        $error_level = $1;
    } else {
        $message = lcfirst($message);
    };
    $exit = 1 if $error_level ne 'ERROR';

    $details->{message}   = $message;
    $details->{err_level} = $error_level;

    report_message( $details, $exit );
}

sub process_warnings
{
    my ( $details, $die ) = @_;

    my $message = $details->{message};
    # Messages with missing STATUS identifiers probably did not originate in
    # COD modules (for example, system errors) and might start with an
    # uppercase letter
    my $error_level = 'WARNING';
    if ( $message =~ s/^([A-Z]+),\s*// ) {
        $error_level = $1;
    } else {
        $message = lcfirst($message);
    };
    my $exit = defined $die->{$error_level} ? $die->{$error_level} : 1;

    $details->{message}   = $message;
    $details->{err_level} = $error_level;

    report_message( $details, $exit );
}

1;
