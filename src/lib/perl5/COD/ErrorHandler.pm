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
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( process_warnings process_errors
                     process_parser_messages report_message );

sub process_parser_messages
{
    my ( $messages, $die_on_error_level, $print_order) = (@_);
    $print_order = [ 'NOTE', 'WARNING', 'ERROR' ] if !defined $print_order;

    my $filename;
    my %err_level_counter;
    foreach ( @$messages ) {
        warn $_;
        my $parsed_message = parse_message($_);
        if ( defined $parsed_message->{errlevel} ) {
            $err_level_counter{$parsed_message->{errlevel}}++;
        };
        if ( defined $parsed_message->{filename} && !defined $filename ) {
            $filename = $parsed_message->{filename};
        }
    };

    foreach ( @$print_order ) {
        if ( defined $err_level_counter{$_} && $err_level_counter{$_} > 0 ) {
            my $message = sprint_message( 
                            $0, $filename, undef,
                            $die_on_error_level->{$_} ? 'ERROR' : 'NOTE',
                            "$err_level_counter{$_} $_(s) encountered "
                          . 'while parsing the file',
                            $die_on_error_level->{$_} ? 
                            "die on $_(s) requested" : undef);
            $die_on_error_level->{$_} ? die $message : warn $message;
        }
    };
};

sub report_message
{
    my ( $program, $filename, $dataname, $error_level, $message, $exit ) = @_;

    $message = sprint_message( $program,
                               $filename,
                               $dataname,
                               $error_level,
                               $message,
                               undef
                             );

    print STDERR $message;
    if ( $exit ) {
        print STDERR sprint_message( $program, $filename, $dataname, 'ERROR',
                                     "1 $error_level(s) encountered -- die on "
                                   . "$error_level(s) requested", undef ) ;
        exit 1;
    }
}

sub process_errors
{
    my ( $filename, $dataname, $message, $exit ) = @_;

    $message =~ s/^([A-Z]+),\s*//;
    # Messages with missing STATUS identifiers probably did not originate in
    # COD modules (for example, system errors) and might start with a
    # uppercase letter
    if ( !$1 ) {
        $message = lcfirst($message);
    };
    my $error_level = defined $1 ? $1 : 'ERROR';
    $exit = 1 if $error_level ne 'ERROR';

    report_message($0, $filename, $dataname, $error_level, $message, $exit);
}

sub process_warnings
{
    my ( $filename, $dataname, $message, $die ) = @_;

    $message =~ s/^([A-Z]+),\s*//;
    # Messages with missing STATUS identifiers probably did not originate in
    # COD modules (for example, system errors) and might start with a
    # uppercase letter
    if ( !$1 ) {
        $message = lcfirst($message);
    };
    my $error_level = defined $1 ? $1 : 'WARNING';
    my $exit = defined $die->{$error_level} ? $die->{$error_level} : 1;

    report_message($0, $filename, $dataname, $error_level, $message, $exit);
}
