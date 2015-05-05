#------------------------------------------------------------------------------
#$Author: andrius $
#$Date: 2015-05-04 09:01:02 +0200 (Mon, 04 May 2015) $ 
#$Revision: 1551 $
#$URL: svn://www.crystallography.net/cod-tools/trunk/src/lib/perl5/COD/CIFData/CIFSymmetryGenerator.pm $
#------------------------------------------------------------------------------
#*
#  Common subroutines for extracting data/creating data structures from
#  the parsed CIF data structures.
#**

package COD::CIFData;

use strict;
use warnings;
use COD::Spacegroups::SymopLookup;
use COD::Spacegroups::SpacegroupNames;
use COD::UserMessage;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    get_cell
    get_symmetry_operators
);

my %sg_name_abbrev =
    map { my $key = $_->[1]; $key =~ s/\s+//g; ( $key, $_->[2] ) }
    @COD::Spacegroups::SpacegroupNames::names,
    map { [ $_->{number}, $_->{hermann_mauguin}, $_->{universal_h_m} ] }
    @COD::Spacegroups::SymopLookup::table,
    @COD::Spacegroups::SymopLookup::extra_settings;

#===============================================================#
# Extract unit cell angles and lengths.

# Accepts
#     values - a hash where a data from the CIF file is stored
# Returns
#     cell_lengths_and_angles - an array  with stored information.

sub get_cell($$$@)
{
    my( $values, $filename, $dataname, $options ) = @_;
    $options = {} unless $options;

    my @cell_lengths_and_angles;

    for my $cif_tag (qw(_cell_length_a
                        _cell_length_b
                        _cell_length_c
                        ))
    {
        if( exists $values->{$cif_tag} ) {
            push(@cell_lengths_and_angles, $values->{$cif_tag}[0]);
            $cell_lengths_and_angles[-1] =~ s/\(\d+\)$//;
        } elsif( $options->{silent} ) {
            push(@cell_lengths_and_angles, undef);
        } else {
            error( $0, $filename, $dataname,
                   "cell length '$cif_tag' not present" );
        }
    }

    for my $cif_tag (qw(_cell_angle_alpha
                        _cell_angle_beta
                        _cell_angle_gamma
                        ))
    {
        if( exists $values->{$cif_tag} ) {
            push( @cell_lengths_and_angles, $values->{$cif_tag}[0] );
            $cell_lengths_and_angles[-1] =~ s/\(\d+\)$//;
        } elsif( $options->{silent} ) {
            push(@cell_lengths_and_angles, undef);
        } else {
            warning( $0, $filename, $dataname,
                     "cell angle '$cif_tag' not present -- " .
                     "taking default value 90 degrees" );
            push( @cell_lengths_and_angles, 90 );
        }
    }

    return @cell_lengths_and_angles;
}

sub get_symmetry_operators($$)
{
    my ( $dataset, $filename ) = @_;

    my $values = $dataset->{values};

    my $sym_data;

    if( exists $values->{"_space_group_symop_operation_xyz"} ) {
        $sym_data = $values->{"_space_group_symop_operation_xyz"};
    } elsif( exists $values->{"_symmetry_equiv_pos_as_xyz"} ) {
        $sym_data = $values->{"_symmetry_equiv_pos_as_xyz"};
    }

    if( !defined $sym_data ) {
        for my $tag (qw( _space_group_name_Hall
                         _space_group_name_hall
                         _symmetry_space_group_name_Hall 
                         _symmetry_space_group_name_hall 
                     )) {
            if( exists $values->{$tag} ) {
                my $hall = $values->{$tag}[0];
                next if $hall eq '?';
                $sym_data = lookup_symops("hall", $hall);

                if( !$sym_data ) {
                    error( $0, $filename, $dataset->{name},
                           "$tag value '$hall' is not recognised" );
                } else {
                    last
                }
            }
        }
    }

    if( !defined $sym_data ) {
        for my $tag (qw( _space_group_name_H-M_alt
                         _space_group_name_h-m_alt
                         _space_group.name_H-M_full
                         _space_group.name_h-m_full
                         _symmetry_space_group_name_H-M
                         _symmetry_space_group_name_h-m
                    )) {
            if( exists $values->{$tag} ) {
                my $h_m = $values->{$tag}[0];
                next if $h_m eq '?';
                $sym_data = lookup_symops("hermann_mauguin", $h_m);

                if( !$sym_data ) {
                    error( $0, $filename, $dataset->{name},
                           "$tag value '$h_m' is not recognised" );
                } else {
                    last
                }
            }
        }
    }

    if( not defined $sym_data ) {
        for my $tag (qw( _space_group_ssg_name
                         _space_group_ssg_name_IT
                         _space_group_ssg_name_WJJ
                    )) {
            if( exists $values->{$tag} ) {
                my $ssg_name = $values->{$tag}[0];
                next if $ssg_name eq '?';

                my $h_m = $ssg_name;
                $h_m =~ s/\(.*//g;
                $h_m =~ s/[\s_]+//g;

                $sym_data = lookup_symops("hermann_mauguin", $h_m);

                if( !$sym_data ) {
                    error( $0, $filename, $dataset->{name},
                           "$tag value '$ssg_name' yielded H-M " .
                           "symbol '$h_m' which is not in our tables" );
                } else {
                    last
                }
            }
        }
    }

    if( not defined $sym_data ) {
        error( $0, $filename, $dataset->{name},
               "neither symmetry operators, " .
               "nor Hall spacegroup symbol, " .
               "nor Hermann-Mauguin spacegroup symbol could be processed" );
        die;
    }

    return $sym_data;
}

#===============================================================#
# @COD::Spacegroups::SymopLookup::table =
# (
# {
#     number          => 1,
#     hall            => ' P 1',
#     schoenflies     => 'C1^1',
#     hermann_mauguin => 'P 1',
#     universal_h_m   => 'P 1',
#     symops => [
#         'x,y,z',
#     ],
#     ncsym => [
#         'x,y,z',
#     ]
# },
# );

sub lookup_symops
{
    my ($option, $param) = @_;

    $param =~ s/ //g;
    $param =~ s/_//g;

    my $sg_full = $sg_name_abbrev{$param};

    $sg_full = "" unless defined $sg_full;
    $sg_full =~ s/\s+//g;

    foreach my $hash (@COD::Spacegroups::SymopLookup::table,
                      @COD::Spacegroups::SymopLookup::extra_settings)
    {
        my $value = $hash->{$option};
        $value =~ s/ //g;
        $value =~ s/_//g;

        if( $value eq $param || $value eq $sg_full )
        {
            return $hash->{symops};
        }
    }
    return undef;
}

1;
