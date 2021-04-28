#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  A list of CIF dictionary tags.
#**

package COD::CIF::Tags::COD;

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    @tag_list
);

# Extracted from DDL1 cod_cif.dic dictionary version 0.040
our @tag_list = qw (
_[local]_cod_duplicate_entry
_[local]_cod_data_source_file
_[local]_cod_data_source_block
_[local]_cod_data_source_MD5_sum
_[local]_cod_data_source_SHA1_sum
_[local]_cod_data_source_SHA256_sum
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
_cod_changelog_entry_author
_cod_changelog_entry_date
_cod_changelog_entry_id
_cod_changelog_entry_text
_cod_data_source_file
_cod_data_source_block
_cod_data_source_URI
_cod_data_source_URL
_cod_data_source_URN
_cod_data_source_MD5_sum
_cod_data_source_SHA1_sum
_cod_data_source_SHA256_sum
_cod_depositor_comments
_cod_depositor_requested_release_date
_cod_entry_issue_author
_cod_entry_issue_date
_cod_entry_issue_description
_cod_entry_issue_id
_cod_entry_issue_origin
_cod_entry_issue_severity
_cod_error_flag
_cod_error_source
_cod_error_description
_cod_cif_authors_sg_H-M
_cod_cif_authors_sg_Hall
_cod_cif_authors_sg_number
_cod_original_cell_volume
_cod_original_sg_number
_cod_original_sg_symbol_Hall
_cod_original_sg_symbol_H-M
_cod_original_formula_moiety
_cod_original_formula_iupac
_cod_original_formula_sum
_cod_original_formula_units_Z
_cod_original_formula_weight
_cod_same_crystal_as
_cod_struct_determination_method
_cod_structure_determination_method
_cod_suboptimal_structure
_cod_related_optimal_struct
_cod_related_suboptimal_struct
_cod_related_diffrn_file_code
_cod_related_duplicate_entry_code
_cod_related_enantiomer_entry_code
_cod_related_entry
_cod_related_entry_id
_cod_related_entry_code
_cod_related_entry_database
_cod_related_entry_description
_cod_related_entry_uri
_cod_chemical_formula_sum_orig
_cod_chemical_formula_moiety_orig
_cod_citation_special_details
_cod_related_optimal_entry_code
_cod_related_same_structure_entry_code
_cod_related_structure_entry_code
_cod_related_suboptimal_entry_code
_cod_text
_cod_database_code
_cod_database_code_structure
_cod_database_code_diffrn_file
_cod_database_fobs_code
_cod_database_coordinates_code
_cod_hold_until_date
);

1;
