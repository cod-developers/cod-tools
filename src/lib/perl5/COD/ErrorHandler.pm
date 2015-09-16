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
use COD::UserMessage qw( sprint_message );
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( process_warnings process_errors );


sub process_errors
{
    my ( $filename, $dataname, $message, $die ) = @_;

    $message =~ s/^([A-Z]+),\s*//;
    # Messages with missing STATUS identifiers probably did not originate in
    # COD modules (for example, system errors) and might start with a
    # uppercase letter
    if ( !$1 ) {
        $message = lcfirst($message);
    };
    my $error_level = defined $1 ? $1 : 'ERROR';

    $message = sprint_message( $0,
                               $filename,
                               $dataname,
                               $error_level,
                               $message,
                               undef
                             );

    if ( $error_level ne 'ERROR' || $die ) {
       CORE::die $message;
    } else {
       print STDERR $message;
    };
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
    if ( defined $die->{$error_level} && $die->{$error_level} ) {
       CORE::die "$error_level, $message";
    } else {
       print STDERR sprint_message( $0, $filename, $dataname,
                                    $error_level, $message, undef );
    }
}
