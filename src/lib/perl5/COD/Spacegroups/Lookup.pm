#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  Basic functions for space group look up.
#**

package COD::Spacegroups::Lookup;

use strict;
use warnings;
use COD::Spacegroups::Lookup::COD;
use COD::Spacegroups::Symop::Parse;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( mk_symop_key mkhash );

sub mk_symop_key
{
    my ( $symops ) = @_;
    return join ";", sort map {symop_string_canonical_form($_)} @$symops;
}

sub mkhash
{
    if( 1 ) {
        map { (mk_symop_key($_->{symops}), $_) }
        @COD::Spacegroups::Lookup::COD::table,
        @COD::Spacegroups::Lookup::COD::extra_settings;
    } else {
        require COD::Spacegroups::Lookup::CCP4;
        map { (mk_symop_key($_->{symops}), $_) }
        @COD::Spacegroups::Lookup::CCP4::table;
    }
}

