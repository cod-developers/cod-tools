#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  Simple usage message generator.
#**

package COD::SUsage;

use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( usage );
our @EXPORT_OK = qw( options );

sub usage
{
    my $script = shift;
    $script = $0 unless defined $script;

    open( SCRIPT, $script ) or die("Could not open $script: $!");
    while( <SCRIPT> ) {
        if( /^\s*#\*/ .. /^\s*#\*\*/ ) {
            /^\s*#\*?\*?/;
            my $line = "$'";
            $line =~ s/\$0/$0/g;
            print $line;
        }
    }
    close( SCRIPT );
}

sub options
{
    my $script = shift;
    $script = $0 unless defined $script;

    print "$script: The '--options' option is a placehoder.\n";
    print "$script: It should be replaced by one of the following options:\n";
    open( SCRIPT, $0 ) or die $!;
    while( <SCRIPT> ) {
        if( /^#\*\s+OPTIONS:/../^#\*\*/ ) {
            s/^#\*\s+OPTIONS://;
            s/^#\*\*?//;
            print;
        }
    }
    close( SCRIPT );
}
