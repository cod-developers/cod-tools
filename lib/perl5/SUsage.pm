#------------------------------------------------------------------------
#$Author: saulius $
#$Date: 2006-05-03 13:16:28 +0300 (Wed, 03 May 2006) $ 
#$Revision: 988 $
#$URL: svn+ssh://lokys.ibt.lt/home/saulius/svn-repositories/cce/aux/SUsage.pm $
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
