#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  A list of CIF dictionary tags used in AMCSD database.
#**

package COD::CIF::Tags::AMCSD;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    @tag_list
);

our @tag_list = qw (
    _amcsd_formula_title
    _amcsd_database_code
    _amcsd_sample_locality
);

1;
