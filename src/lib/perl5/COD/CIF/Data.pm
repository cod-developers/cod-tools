#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Common subroutines for extracting data/creating data structures from
#  the parsed CIF data structures.
#**

package COD::CIF::Data;

use strict;
use warnings;
use COD::Spacegroups::Lookup::COD;
use COD::Spacegroups::Names;

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    get_cell
    get_content_encodings
    get_symmetry_operators
);

my %sg_name_abbrev =
    map { my $key = $_->[1]; $key =~ s/\s+//g; ( $key, $_->[2] ) }
    @COD::Spacegroups::Names::names,
    map { [ $_->{'number'}, $_->{'hermann_mauguin'}, $_->{'universal_h_m'} ] }
    @COD::Spacegroups::Lookup::COD::table,
    @COD::Spacegroups::Lookup::COD::extra_settings;

#===============================================================#
# Extract unit cell angles and lengths.

# Accepts
#     values
#               Reference to a hash where data from the CIF file is stored.
#     options
#               Reference to a hash that holds subroutine options.
#               The accepted options are:
#                   'silent'
#                           Flag value, that controls the way missing
#                           values are treated. If set to true,
#                           'undef' values are returned instead of
#*                          missing values without raising any warnings,
#*                          error or assuming default values (default false).
# Returns
#     cell_lengths_and_angles - an array  with stored information.

sub get_cell
{
    my( $values, $options ) = @_;
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
            die "ERROR, cell length tag '$cif_tag' not present" . "\n";
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
            warn( "WARNING, cell angle tag '$cif_tag' not present -- "
                . "taking default value 90 degrees\n" );
            push( @cell_lengths_and_angles, 90 );
        }
    }

    return @cell_lengths_and_angles;
}

sub get_symmetry_operators($)
{
    my ( $dataset ) = @_;

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
                    warn "WARNING, '$tag' tag value '$hall' was not "
                       . "recognised as a space group name\n";
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
                    warn "WARNING, '$tag' tag value '$h_m' was not "
                       . "recognised as a space group name\n";
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
                    warn "WARNING, '$tag' tag value '$ssg_name' yielded H-M " .
                         "symbol '$h_m' which is not in our tables\n";
                } else {
                    last
                }
            }
        }
    }

    if( not defined $sym_data ) {
        die 'ERROR, neither symmetry operator tag values, '
          . 'nor Hall space group name, '
          . 'nor Hermann-Mauguin space group name '
          . "could be processed to acquire symmetry operators\n";
    }

    return $sym_data;
}

sub get_content_encodings($)
{
    my ( $dataset ) = @_;

    my $values = $dataset->{values};

    if( !exists $values->{_tcod_content_encoding_id} ||
        !exists $values->{_tcod_content_encoding_layer_type} ) {
        return undef;
    }

    my %encodings;

    for( my $i = 0; $i < @{$values->{_tcod_content_encoding_id}}; $i++ ) {
        my $id         = $values->{_tcod_content_encoding_id}[$i];
        my $layer_type = $values->{_tcod_content_encoding_layer_type}[$i];
        my $layer_id;

        if( exists $values->{_tcod_content_encoding_layer_id} ) {
            $layer_id = $values->{_tcod_content_encoding_layer_id}[$i];
        }

        if( exists $encodings{$id} && !defined $layer_id ) {
            die "ERROR, content encoding '$id' has more than unnumbered layer"
              . 'cannot unambiguously reconstruct encoding stack' . "\n" ;
        }

        $layer_id = 0 if !defined $layer_id;
        if( int($layer_id) != $layer_id ) {
            die "ERROR, the detected content encoding "
               . "layer ID '$layer_id' is not an integer\n";
        }

        if( !exists $encodings{$id} ) {
            $encodings{$id} = {};
        }

        if( !exists $encodings{$id}{$layer_id} ) {
            $encodings{$id}{$layer_id} = $layer_type;
        } else {
            die "ERROR, more than one content encoding layer numbered " .
                "'$layer_id' detected\n";
        }
    }

    my %encodings_now;
    for my $stack (keys %encodings) {
        $encodings_now{$stack} = [ map { $encodings{$stack}{$_} }
                                   sort keys %{$encodings{$stack}} ];
    }
    return \%encodings_now;
}

#===============================================================#
# @COD::Spacegroups::Lookup::COD::table =
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

    foreach my $hash (@COD::Spacegroups::Lookup::COD::table,
                      @COD::Spacegroups::Lookup::COD::extra_settings)
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
