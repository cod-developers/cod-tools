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
_[local]_cod_superseeded_by
_[local]_cod_data_source_file
_[local]_cod_data_source_block
_[local]_cod_published_source
_[local]_cod_data_source_MD5_sum
_[local]_cod_data_source_SHA1_sum
_[local]_cod_data_source_SHA256_sum
_[local]_cod_est_spacegroup_name_H-M
_[local]_cod_depositor_comments
_[local]_cod_error_flag
_[local]_cod_error_source
_[local]_cod_error_description
_[local]_cod_cif_authors_sg_H-M
_[local]_cod_cif_authors_sg_Hall
_[local]_cod_cif_authors_sg_number
_[local]_cod_original_cell_volume
_[local]_cod_suboptimal_structure
_[local]_cod_related_optimal_struct
_[local]_cod_related_suboptimal_struct
_[local]_cod_chemical_formula_sum_orig
_[local]_cod_chemical_formula_moiety_orig
_[local]_cod_citation_special_details
_[local]_cod_text

_cod_enantiomer_of
_cod_duplicate_entry
_cod_superseeded_by
_cod_data_source_file
_cod_data_source_block
_cod_published_source
_cod_data_source_MD5_sum
_cod_data_source_SHA1_sum
_cod_data_source_SHA256_sum
_cod_est_spacegroup_name_H-M
_cod_depositor_comments
_cod_error_flag
_cod_error_source
_cod_error_description
_cod_cif_authors_sg_H-M
_cod_cif_authors_sg_Hall
_cod_cif_authors_sg_number
_cod_original_cell_volume
_cod_original_sg_symbol_Hall
_cod_original_formula_sum
_cod_original_formula_weight
_cod_suboptimal_structure
_cod_related_optimal_struct
_cod_related_suboptimal_struct
_cod_related_entry
_cod_related_entry_database
_cod_related_entry_description
_cod_chemical_formula_sum_orig
_cod_chemical_formula_moiety_orig
_cod_citation_special_details
_cod_text
_cod_database_code
_cod_database_fobs_code
);

1;
