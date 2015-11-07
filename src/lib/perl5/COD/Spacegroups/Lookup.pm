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
    my ( $space_group_sets ) = @_;

    return map { (mk_symop_key($_->{symops}), $_) }
               map { @$_ } @$space_group_sets;
}

