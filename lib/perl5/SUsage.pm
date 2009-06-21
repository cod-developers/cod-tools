#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  Simple usage message generator
#**

package SUsage;

use strict;
require Exporter;
@SUsage::ISA = qw(Exporter);
@SUsage::EXPORT = qw( usage );

sub usage
{
    my $script = shift;
    $script = $0 unless defined $script;

    open( SCRIPT, $script ) or die("Could not open $script: $!");
    while( <SCRIPT> ) {
	if( /^\s*#\*/ .. /^\s*#\*\*/ ) {
	    /^\s*#\*?\*?/;
	    print "$'";
        }
    }
    close SCRIPT;
}
