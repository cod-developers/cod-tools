#------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------
#*
#  A list of CIF dictionary tags excluded from COD files.
#**

package COD::CIF::Tags::Excluded;

use strict;
use warnings;
require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    @tag_list
);

our @iurc_tags = qw (
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
_publ_vrn_code
_vrf_[]
_vrf_VALIDATOR_comments
);

##
# The following data names where extracted from the 'cif_ccdc.dic' dictionary.
# Metadata of the source dictionary:
#
# Dictionary name: cif_ccdc.dic
# Dictionary version: 1.3
# Last updated on: 2014-05-12
# Retrieved on: 2020-05-18
# Retrieved from: ftp://ftp.iucr.org/pub/cifdics/cif_ccdc.dic
##
my @ccdc_dic_tags = qw(
_ccdc_depnum_archive
_ccdc_depnum_russian
_ccdc_geom_angle
_ccdc_geom_angle_atom_site_label_1
_ccdc_geom_angle_atom_site_label_2
_ccdc_geom_angle_atom_site_label_3
_ccdc_geom_angle_fragment_id
_ccdc_geom_angle_parameter_label
_ccdc_geom_angle_query_id
_ccdc_geom_angle_site_symmetry_1
_ccdc_geom_angle_site_symmetry_2
_ccdc_geom_angle_site_symmetry_3
_ccdc_geom_angle_transformation
_ccdc_geom_bond_type
_ccdc_geom_distance
_ccdc_geom_distance_atom_site_label_1
_ccdc_geom_distance_atom_site_label_2
_ccdc_geom_distance_fragment_id
_ccdc_geom_distance_parameter_label
_ccdc_geom_distance_query_id
_ccdc_geom_distance_site_symmetry_1
_ccdc_geom_distance_site_symmetry_2
_ccdc_geom_distance_transformation
_ccdc_geom_torsion
_ccdc_geom_torsion_atom_site_label_1
_ccdc_geom_torsion_atom_site_label_2
_ccdc_geom_torsion_atom_site_label_3
_ccdc_geom_torsion_atom_site_label_4
_ccdc_geom_torsion_fragment_id
_ccdc_geom_torsion_parameter_label
_ccdc_geom_torsion_query_id
_ccdc_geom_torsion_site_symmetry_1
_ccdc_geom_torsion_site_symmetry_2
_ccdc_geom_torsion_site_symmetry_3
_ccdc_geom_torsion_site_symmetry_4
_ccdc_geom_torsion_transformation
_ccdc_journal_manuscript_code
_ccdc_publ_extra_info
);

our @ccdc_tags = (
@ccdc_dic_tags,
qw (
_ccdc_biological_activity
_ccdc_chemical_compound_source_recrystallisation
_ccdc_chemdiag_records
_ccdc_chemdiag_type
_ccdc_comments
_ccdc_compound_id
_ccdc_disorder
_ccdc_journal_depnumber
_ccdc_polymorph
_citation_database_id_CSD
_database_code_ccdc
_database_code_CSD
_database.code_CSD
_database_code_depnum_ccdc_archive
_database.code_depnum_ccdc_archive
_database_code_depnum_ccdc_fiz
_database.code_depnum_ccdc_fiz
_database_code_depnum_ccdc_journal
_database.code_depnum_ccdc_journal
_database_code_depnum_csd_archive
)
);

our @icsd_tags = qw (
_database_code_depnum_icsd_archive
_database_code_ICSD
_database.code_ICSD
);

our @potentially_copyrighted_tags = qw(
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

_atom_sites_special_details
_cell_special_details
_diffrn_special_details
_exptl_special_details
_geom_special_details
_pd_calibration_special_details
_pd_char_special_details
_pd_instr_special_details
_pd_meas_special_details
_pd_peak_special_details
_pd_proc_info_special_details
_pd_proc_ls_special_details
_pd_spec_special_details
_refine_special_details
_reflns_special_details

_publ_vrn_code

_publ_contact_letter
_publ.contact_letter
);

our @tag_list = (
    @iurc_tags,
    @ccdc_tags,
    @icsd_tags,
    @potentially_copyrighted_tags
);

1;
