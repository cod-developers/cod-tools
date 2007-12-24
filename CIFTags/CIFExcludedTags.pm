#------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------
#* 
#  A list of CIF dictionary tags excluded from COD files.
#**

package CIFExcludedTags;

use strict;
require Exporter;
@CIFExcludedTags::ISA = qw(Exporter);
@CIFExcludedTags::EXPORT_OK = qw(@tag_list);

@CIFExcludedTags::tag_list = (
    @CIFExcludedTags::iurc_tags,
    @CIFExcludedTags::ccdc_tags,
    @CIFExcludedTags::icsd_tags,
    @CIFExcludedTags::potentially_copyrighted_tags
);

@CIFExcludedTags::iurc_tags = qw (
_iucr_compatibility_tag
_geom_extra_table_[]
_geom_extra_tableA_col_1
_geom_extra_tableA_col_2
_geom_extra_tableA_col_3
_geom_extra_tableA_col_4
_geom_extra_tableA_col_5
_geom_extra_tableA_col_6
_geom_extra_tableA_col_7
_geom_extra_tableA_col_8
_geom_extra_tableA_col_9
_geom_extra_tableA_col_10
_geom_extra_tableA_col_11
_geom_extra_tableA_col_12
_geom_extra_tableA_col_13
_geom_extra_tableA_col_14
_geom_extra_tableB_col_1
_geom_extra_tableB_col_2
_geom_extra_tableB_col_3
_geom_extra_tableB_col_4
_geom_extra_tableB_col_5
_geom_extra_tableB_col_6
_geom_extra_tableB_col_7
_geom_extra_tableB_col_8
_geom_extra_tableB_col_9
_geom_extra_tableB_col_10
_geom_extra_tableB_col_11
_geom_extra_tableB_col_12
_geom_extra_tableB_col_13
_geom_extra_tableB_col_14
_geom_extra_tableC_col_1
_geom_extra_tableC_col_2
_geom_extra_tableC_col_3
_geom_extra_tableC_col_4
_geom_extra_tableC_col_5
_geom_extra_tableC_col_6
_geom_extra_tableC_col_7
_geom_extra_tableC_col_8
_geom_extra_tableC_col_9
_geom_extra_tableC_col_10
_geom_extra_tableC_col_11
_geom_extra_tableC_col_12
_geom_extra_tableC_col_13
_geom_extra_tableC_col_14
_geom_extra_tables_[]
_geom_table_footnote_A
_geom_table_footnote_B
_geom_table_footnote_C
_geom_extra_table_head_A
_geom_extra_table_head_B
_geom_extra_table_head_C
_geom_table_headnote_A
_geom_table_headnote_B
_geom_table_headnote_C
_geom_angle_DHA
_geom_bond_atom_site_label_A
_geom_bond_atom_site_label_D
_geom_bond_atom_site_label_H
_geom_bond_distance_DH
_geom_contact_distance_DA
_geom_contact_distance_HA
_geom_contact_site_symmetry_A
_geom_contact_site_symmetry_D
_geom_contact_site_symmetry_H
_publ_vrn_code
_vrf_[]
_vrf_VALIDATOR_comments
);

@CIFExcludedTags::ccdc_tags = qw (
_database_code_depnum_ccdc_archive
_database.code_depnum_ccdc_archive
_database_code_depnum_ccdc_fiz
_database.code_depnum_ccdc_fiz
_database_code_depnum_ccdc_journal
_database.code_depnum_ccdc_journal
);

@CIFExcludedTags::icsd_tags = qw (
_database_code_ICSD
_database.code_ICSD
);

@CIFExcludedTags::potentially_copyrighted_tags = qw(
_publ_body_[]
_publ_body_contents
_publ_body.contents
_publ_body_element
_publ_body.element
_publ_body_format
_publ_body.format
_publ_body_label
_publ_body.label
_publ_body_title
_publ_body.title

_publ_manuscript_creation
_publ.manuscript_creation
_publ_manuscript_incl_[]
_publ_manuscript_incl.entry_id
_publ_manuscript_incl_extra_defn
_publ_manuscript_incl.extra_defn
_publ_manuscript_incl_extra_info
_publ_manuscript_incl.extra_info
_publ_manuscript_incl_extra_item
_publ_manuscript_incl.extra_item
_publ_manuscript_processed
_publ.manuscript_processed
_publ_manuscript_text
_publ.manuscript_text
_publ_requested_category
_publ.requested_category
_publ_requested_coeditor_name
_publ.requested_coeditor_name
_publ_requested_journal
_publ.requested_journal

_publ_section_abstract
_publ.section_abstract
_publ_section_acknowledgements
_publ.section_acknowledgements
_publ_section_comment
_publ.section_comment
_publ_section_discussion
_publ.section_discussion
_publ_section_experimental
_publ.section_experimental
_publ_section_exptl_prep
_publ.section_exptl_prep
_publ_section_exptl_refinement
_publ.section_exptl_refinement
_publ_section_exptl_solution
_publ.section_exptl_solution
_publ_section_figure_captions
_publ.section_figure_captions
_publ_section_introduction
_publ.section_introduction
_publ_section_references
_publ.section_references
_publ_section_synopsis
_publ.section_synopsis
_publ_section_table_legends
_publ.section_table_legends

_exptl_special_details
_geom_special_details

_publ_vrn_code
);

1;
