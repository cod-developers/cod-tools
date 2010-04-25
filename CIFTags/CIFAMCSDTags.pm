#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  A list of CIF dictionary tags used in AMCSD database.
#**

package CIFAMCSDTags;

use strict;

require Exporter;
@CIFAMCSDTags::ISA = qw(Exporter);
@CIFAMCSDTags::EXPORT_OK = qw( @tag_list );

@CIFAMCSDTags::tag_list = qw (
_amcsd_formula_title
_amcsd_database_code
_amcsd_sample_locality
);

1;
