#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  A list of CIF dictionary tags.
#**

package CIFCODTags;

use strict;

require Exporter;
@CIFCODTags::ISA = qw(Exporter);
@CIFCODTags::EXPORT_OK = qw( @tag_list );

@CIFCODTags::tag_list = qw (
_[local]_cod_duplicate_entry
_[local]_cod_data_source_file
_[local]_cod_published_source
_[local]_cod_data_source_MD5_sum
_[local]_cod_data_source_SHA1_sum
_[local]_cod_data_source_SHA256_sum
_[local]_cod_est_spacegroup_name_H-M

_cod_duplicate_entry
_cod_data_source_file
_cod_published_source
_cod_data_source_MD5_sum
_cod_data_source_SHA1_sum
_cod_data_source_SHA256_sum
_cod_est_spacegroup_name_H-M
);

1;
