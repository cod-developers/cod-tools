#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
# Test dataset on various criteria.
#-----------------------------------------------------------------------

package COD::CIF::Data::CODFlags;

use strict;
use warnings;
use COD::CIF::Tags::Manage qw(
    contains_data_item
    has_special_value
    tag_is_empty
);

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    is_on_hold
    is_duplicate
    is_retracted
    is_disordered
    is_suboptimal
    is_theoretical
    has_coordinates
    has_hkl
    has_partially_occupied_ordered_atoms
    has_powder_diffraction_intensities
    has_twin_hkl
    has_Fobs
    has_errors
    has_warnings
    @hkl_tags
    @powder_diffraction_intensity_tags
);

our @hkl_tags = qw(
    _refln_index_h
    _refln_index_k
    _refln_index_l
);

our @powder_diffraction_intensity_tags = qw(
    _pd_meas_counts_total
    _pd_meas_intensity_total
    _pd_proc_intensity_net
    _pd_proc_intensity_total
);

sub is_duplicate($);
sub is_disordered($);
sub is_suboptimal($);
sub is_theoretical($);
sub is_on_hold($);
sub is_retracted($);
sub has_coordinates($);
sub has_hkl($);
sub has_powder_diffraction_intensities($);
sub has_twin_hkl($);
sub has_Fobs($);
sub has_warnings($);
sub has_errors($);

##
# Evaluates if a data block is marked by the COD maintainers as a duplicate
# COD entry.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       '1' if the data block is marked as a duplicate COD entry,
#       '0' otherwise.
##
sub is_duplicate($)
{
    my ($data_block) = @_;
    my $values = $data_block->{'values'};

    my @duplicate_tags = qw(
        _cod_related_duplicate_entry.code
        _cod_related_duplicate_entry_code
        _cod_duplicate_entry
        _[local]_cod_duplicate_entry
    );

    for my $tag (@duplicate_tags) {
        return 1 if exists $values->{$tag};
    }

    return 0;
}

sub is_disordered($)
{
    my ($data_block) = @_;
    my $values = $data_block->{'values'};

    my @disorder_tags = qw(
        _atom_site_disorder_assembly
        _atom_site.disorder_assembly
        _atom_site_disorder_group
        _atom_site.disorder_group
    );

    for my $tag (@disorder_tags) {
        next if !defined $values->{$tag};
        return 1 if !tag_is_empty($data_block, $tag);
    }

    return 0;
}

##
# Evaluates if a data block is marked by the COD maintainers as containing
# a suboptimal description of the structure.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       '1' if the data block is marked as containing a suboptimal description,
#       '0' otherwise.
##
sub is_suboptimal($)
{
    my ($data_block) = @_;
    my $values = $data_block->{'values'};

    my @suboptimal_flag_tags = qw(
        _cod_suboptimal_structure
        _[local]_cod_suboptimal_structure
    );

    for my $tag (@suboptimal_flag_tags) {
        next if !exists $values->{$tag};
        return 1 if $values->{$tag}[0] eq 'yes';
    }

    # suboptimal structures might not be explicitly marked as such,
    # but rather only contain references to the optimal structures
    my @related_optimal_tags = qw(
        _cod_related_optimal_entry.code
        _cod_related_optimal_entry_code
        _cod_related_optimal_struct
        _[local]_cod_related_optimal_struct
    );

    for my $tag ( @related_optimal_tags ) {
        return 1 if exists $values->{$tag};
    }

    return 0;
}

##
# Evaluates if a data block is marked by the COD maintainers as being on hold.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       '1' if the data block is marked as being on hold,
#       '0' otherwise.
##
sub is_on_hold($)
{
    my ($data_block) = @_;
    my $values = $data_block->{'values'};

    my @on_hold_tags = qw(
        _cod_depositor.requested_release_date
        _cod_depositor_requested_release_date
        _cod_hold_until_date
        _[local]_cod_hold_until_date
    );

    for my $tag (@on_hold_tags) {
        return 1 if exists $values->{$tag};
    }

    return 0;
}

##
# Evaluates if a data block is marked by the COD maintainers as describing
# a structure that was determined using theoretical calculations.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       '1' if the data block is marked as describing a theoretically
#           calculated structure,
#       '0' otherwise.
##
sub is_theoretical($)
{
    my ($data_block) = @_;
    my $values = $data_block->{'values'};

    my @determination_method_tags = qw(
        _cod_structure.determination_method
        _cod_structure_determination_method
        _cod_struct_determination_method
    );

    for my $tag (@determination_method_tags) {
        next if !exists $values->{$tag};
        return 1 if $values->{$tag}[0] eq 'theoretical';
    }

    return 0;
}

sub has_coordinates($)
{
    my ($data_block) = @_;

    my @coordinate_tags = qw(
        _atom_site_fract_x
        _atom_site.fract_x
        _atom_site_fract_y
        _atom_site.fract_y
        _atom_site_fract_z
        _atom_site.fract_z
        _atom_site_Cartn_x
        _atom_site.Cartn_x
        _atom_site_Cartn_x_nm
        _atom_site_Cartn_x_pm
        _atom_site_Cartn_y
        _atom_site.Cartn_y
        _atom_site_Cartn_y_nm
        _atom_site_Cartn_y_pm
        _atom_site_Cartn_z
        _atom_site.Cartn_z
        _atom_site_Cartn_z_nm
        _atom_site_Cartn_z_pm
    );

    for my $tag (@coordinate_tags) {
        return 1 if !tag_is_empty($data_block, $tag);
    }

    return 0;
}

sub has_hkl($)
{
    my ($data_block) = @_;

    for my $tag (@hkl_tags) {
        return 0 if !exists $data_block->{'values'}{$tag};
    }

    return 1;
}

sub has_partially_occupied_ordered_atoms($)
{
    my ($data_block) = @_;

    my $values = $data_block->{'values'};

    return 0 if tag_is_empty($data_block, '_atom_site_occupancy') ||
                !contains_data_item($data_block, '_atom_site_disorder_group');

    for my $i (0..$#{$data_block->{'values'}{'_atom_site_label'}}) {
        next if has_special_value($data_block, '_atom_site_occupancy', $i);
        next if has_special_value($data_block, '_atom_site_disorder_group', $i);
        next if $values->{'_atom_site_occupancy'}[$i] == 1;
        return 1;
    }

    return 0;
}

sub has_powder_diffraction_intensities($)
{
    my ($data_block) = @_;

    for my $tag (@powder_diffraction_intensity_tags) {
        return 1 if !tag_is_empty($data_block, $tag);
    }

    return 0;
}

sub has_twin_hkl($)
{
    my ($data_block) = @_;

    return !tag_is_empty($data_block, '_twin_refln_datum_id');
}

##
# Evaluates if a data block is marked by the COD maintainers as having
# a related diffraction file.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       '1' if the data block is marked as having a related diffraction file,
#       '0' otherwise.
##
sub has_Fobs($)
{
    my ($data_block) = @_;

    my @f_obs_tags = qw(
        _cod_related_diffrn_file.code
        _cod_related_diffrn_file_code
        _cod_database_fobs_code
    );

    for my $tag (@f_obs_tags) {
        return 1 if !tag_is_empty($data_block, $tag);
    }

    return 0;
}

##
# Evaluates if a data block contains at least one instance of
# an issue with the given severity value.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @param $error_flag_value
#       Issue severity value that should be checked for. All text
#       strings are supported, but the expected values are limited
#       to 'note', 'warning', 'error' and 'retraction'.
# @return
#       '1' if the data block contains the given error flag value,
#       '0' otherwise.
##
sub has_issue_severity_value
{
    my ($data_block, $severity_value) = @_;
    my $values = $data_block->{'values'};

    my @issue_severity_tags = qw(
        _cod_entry_issue.severity
        _cod_entry_issue_severity
    );

    for my $tag (@issue_severity_tags) {
        next if !exists $values->{$tag};
        for my $value ( @{$values->{$tag}} ) {
            return 1 if $value eq $severity_value;
        };
    }

    return 0;
}

##
# Evaluates if a data block contains at least one instance of
# the given error flag value.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @param $error_flag_value
#       Error flag value that should be checked for. All text strings
#       are supported, but the expected values are limited to
#       'none', 'warnings', 'errors' and 'retracted'.
# @return
#       '1' if the data block contains the given error flag value,
#       '0' otherwise.
##
sub has_error_flag_value
{
    my ($data_block, $error_flag_value) = @_;
    my $values = $data_block->{'values'};

    my @error_flag_tags = qw(
        _cod_error_flag
        _[local]_cod_error_flag
    );

    for my $tag (@error_flag_tags) {
        next if !exists $values->{$tag};
        for my $value (@{$values->{$tag}}) {
            return 1 if $value eq $error_flag_value;
        };
    };

    return 0;
}

##
# Evaluates if a data block is marked by the COD maintainers as having warnings.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       '1' if the data block is marked as having warnings,
#       '0' otherwise.
##
sub has_warnings($)
{
    my ($data_block) = @_;

    return 1 if has_issue_severity_value($data_block, 'warning');
    return 1 if has_error_flag_value($data_block, 'warnings');

    return 0;
}

##
# Evaluates if a data block is marked by the COD maintainers as having errors.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       '1' if the data block is marked as having errors,
#       '0' otherwise.
##
sub has_errors($)
{
    my ($data_block) = @_;
    my $values = $data_block->{'values'};

    return 1 if has_issue_severity_value($data_block, 'error');
    return 1 if has_error_flag_value($data_block, 'errors');

    return 0;
}

##
# Evaluates if a data block is marked by the COD maintainers as being retracted.
#
# @param $data_block
#       Reference to data block as returned by the COD::CIF::Parser.
# @return
#       '1' if the data block is marked as retracted,
#       '0' otherwise.
##
sub is_retracted($)
{
    my ($data_block) = @_;
    my $values = $data_block->{'values'};

    return 1 if has_issue_severity_value($data_block, 'retraction');
    return 1 if has_error_flag_value($data_block, 'retracted');

    return 0;
}

1;
