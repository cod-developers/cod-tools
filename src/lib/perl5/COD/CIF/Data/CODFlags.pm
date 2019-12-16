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
use COD::CIF::Tags::Manage qw( tag_is_empty );

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

sub is_on_hold($)
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};

    my $on_hold_tags = [ '_cod_hold_until_date',
                         '_[local]_cod_hold_until_date' ];

    foreach ( @$on_hold_tags ) {
        return 1 if exists $values->{$_};
    }

    return 0;
}

sub is_retracted($)
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};

    my $retracted_tags = [ '_cod_error_flag',
                           '_[local]_cod_error_flag' ];

    foreach my $tags ( @$retracted_tags ) {
        if ( exists $values->{$tags} ) {
            foreach ( @{$values->{$tags}} ) {
                return 1 if( $_ eq 'retracted' );
            };
        };
    };

    return 0;
}

sub is_theoretical($)
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};

    if( exists $values->{_cod_struct_determination_method} &&
        $values->{_cod_struct_determination_method}[0] eq 'theoretical' ) {
        return 1;
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
    my ( $dataset ) = @_;

    for my $tag ( @hkl_tags ) {
        return 0 if !exists $dataset->{values}{$tag};
    }

    return 1;
}

sub has_powder_diffraction_intensities($)
{
    my ( $dataset ) = @_;

    for my $tag ( @powder_diffraction_intensity_tags ) {
        return 1 if !tag_is_empty( $dataset, $tag );
    }

    return 0;
}

sub has_twin_hkl($)
{
    my ( $dataset ) = @_;

    return !tag_is_empty( $dataset, '_twin_refln_datum_id' );
}

sub has_Fobs($)
{
    my ( $dataset ) = @_;

    my @Fobs_tags = qw(
        _cod_database_fobs_code
    );

    for my $tag ( @Fobs_tags ) {
        return 1 if !tag_is_empty( $dataset, $tag );
    }

    return 0;
}

sub has_warnings($)
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};

    my $warning_tags = [ '_cod_error_flag',
                         '_[local]_cod_error_flag' ];

    foreach my $tags ( @$warning_tags ) {
        if ( exists $values->{$tags} ) {
            foreach ( @{$values->{$tags}} ) {
                return 1 if( $_ eq 'warnings' );
            };
        };
    };

    return 0;
}

sub has_errors($)
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};

    my $errors_tags = [ '_cod_error_flag',
                        '_[local]_cod_error_flag' ];

    foreach my $tags ( @$errors_tags ) {
        if ( exists $values->{$tags} ) {
            foreach ( @{$values->{$tags}} ) {
                return 1 if( $_ eq 'errors' );
            };
        };
    };

    return 0;
}

1;
