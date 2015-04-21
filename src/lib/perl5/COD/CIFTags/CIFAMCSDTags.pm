#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  A list of CIF dictionary tags used in AMCSD database.
#**

package COD::CIFTags::CIFAMCSDTags;

use strict;

require Exporter;
@COD::CIFTags::CIFAMCSDTags::ISA = qw(Exporter);
@COD::CIFTags::CIFAMCSDTags::EXPORT_OK = qw( @tag_list );

@COD::CIFTags::CIFAMCSDTags::tag_list = qw (
_amcsd_formula_title
_amcsd_database_code
_amcsd_sample_locality
);

1;
