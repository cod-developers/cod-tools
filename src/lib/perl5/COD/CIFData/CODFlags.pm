#--*-perl-*-------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#-----------------------------------------------------------------------
# Test dataset on various criteria.
#-----------------------------------------------------------------------

package COD::CIFData::CODFlags;

use strict;
use warnings;
use COD::CIFTags::CIFTagManage qw( tag_is_empty );
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( is_on_hold
                  is_duplicate
                  is_retracted
                  is_disordered
                  is_suboptimal
                  has_errors
                  has_warnings
                );

sub is_duplicate($);
sub is_disordered($);
sub is_suboptimal($);
sub is_on_hold($);
sub is_retracted($);
sub has_warnings($);
sub has_errors($);

sub is_duplicate($)
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};

    my $duplicate_tags = [ '_cod_duplicate_entry', 
                           '_[local]_cod_duplicate_entry' ];

    foreach ( @$duplicate_tags ) {
        return 1 if exists $values->{$_};
    }

    return 0;
}

sub is_disordered($)
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};

    my $disorder_tags = [ '_atom_site_disorder_assembly',
                          '_atom_site.disorder_assembly',
                          '_atom_site_disorder_group',
                          '_atom_site.disorder_group' ];

    foreach ( @$disorder_tags ) {
        return 1 if ( exists $values->{$_} && ! tag_is_empty( $dataset, $_ ) );
    }

    return 0;
}

sub is_suboptimal($)
{
    my ( $dataset ) = @_;
    my $values = $dataset->{values};

    my $suboptimal_tags = [ '_cod_suboptimal_structure',
                            '_[local]_cod_suboptimal_structure' ];

    foreach ( @$suboptimal_tags ) {
        return 1 if( exists $values->{$_} && $values->{$_} eq 'yes' );
    }

    # structures might not be explicitly marked as suboptimal 
    # but it could be implied from the presence of the following tags
    $suboptimal_tags = [ '_cod_related_optimal_struct',
                         '_[local]_cod_related_optimal_struct' ];

    foreach ( @$suboptimal_tags ) {
        return 1 if exists $values->{$_};
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
