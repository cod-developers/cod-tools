#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision: 131 $
#$URL$
#------------------------------------------------------------------------------
#*
#  Format run time error and warning messages in a uniform way.
#**

package UserMessage;

use strict;
use warnings;
require Exporter;
@UserMessage::ISA = qw(Exporter);
@UserMessage::EXPORT = qw( error warning );

#==============================================================================
# Print a message, reporting a program name, file name, data block
# name and am error level (ERROR or WARNING) in a uniform way.
#
# For ease of parsing error messages from log files, $message should
# probably not contain a colon (":") since colon is used to separate
# different parts of the error message.

sub print_message($$$$$)
{
    my ( $program, $filename, $datablock, $errlevel, $message ) = @_;

    print STDERR $program, ": ", $filename,
    defined $datablock ? " data_" . $datablock : "",
    defined $errlevel ? ": " . $errlevel : "",
    ": ", $message, ".\n";
}

#==============================================================================
# Report an error message. Errors are indicated with the "ERROR"
# keyword in the message line. This is supposed to be a fatal even,
# and the program will most probably die() or exit(255) after this
# message, but the UserMessage package does not enforce this policy.

sub error($$$$)
{
    my ( $program, $filename, $datablock, $message ) = @_;
    print_message( $program, $filename, $datablock, "ERROR", $message );
}

#==============================================================================
# Report a warning message. Warning are indicated with the "WARNING"
# keyword. Program can probably continue after warnings and give a
# reasonable result, but it might be not the result which the user
# expected.

sub warning($$$$)
{
    my ( $program, $filename, $datablock, $message ) = @_;
    print_message( $program, $filename, $datablock, "WARNING", $message );
}

1;
