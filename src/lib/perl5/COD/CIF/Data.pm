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
use COD::CIF::Tags::Manage qw( has_special_value
                               has_unknown_value
                               has_inapplicable_value );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    get_cell
    get_formula_units_z
    get_sg_data
    get_content_encodings
    get_source_data_block_name
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
        if( exists $values->{$cif_tag} &&
            defined $values->{$cif_tag}[0] ) {
            push(@cell_lengths_and_angles, $values->{$cif_tag}[0]);
            $cell_lengths_and_angles[-1] =~ s/\(\d+\)$//;
        } elsif( $options->{silent} ) {
            push(@cell_lengths_and_angles, undef);
        } else {
            die "ERROR, cell length data item '$cif_tag' not present" . "\n";
        }
    }

    for my $cif_tag (qw(_cell_angle_alpha
                        _cell_angle_beta
                        _cell_angle_gamma
                        ))
    {
        if( exists $values->{$cif_tag} &&
            defined $values->{$cif_tag}[0] ) {
            push( @cell_lengths_and_angles, $values->{$cif_tag}[0] );
            $cell_lengths_and_angles[-1] =~ s/\(\d+\)$//;
        } elsif( $options->{silent} ) {
            push(@cell_lengths_and_angles, undef);
        } else {
            warn( "WARNING, cell angle data item '$cif_tag' not present -- "
                . "taking default value 90 degrees\n" );
            push( @cell_lengths_and_angles, 90 );
        }
    }

    return @cell_lengths_and_angles;
}

##
# Constructs a structure containing symmetry information using only the data
# present in the data block.
# @param $values
#       The 'values' hash extracted from the CIF structure as returned by the
#       CIF::COD::Parser.
# @return $sg_data
#       A structure containing the symmetry information present in the data
#       block. Example of the returned data structure:
#
#       $sg_data = {
#           'hermann_mauguin' => 'P -1',
#           'hall'            => '-P 1',
#           'number'          => 2,
#           'symop_ids'       =>
#                       [
#                         1
#                         2
#                       ],
#           'symops' =>
#                       [
#                          'x, y, z',
#                          '-x, -y, -z'
#                       ];
#           'tags' => {
#               'hermann_mauguin' => '_space_group_name_H-M_alt'
#               'hall'      => '_space_group_name_Hall'
#               'number'    => '_space_group_IT_number'
#               'symop_ids' => '_space_group_symop_id'
#               'symops'    => '_space_group_symop_operation_xyz'
#           }
#       }
#
# The following fields can be potentially defined in the structure:
#
#       'hall'
#                           Space group symbol in Hall notation.
#       'hermann_mauguin'
#                           Space group symbol in Hermann-Mauguin notation.
#       'number'
#                           Space group number defined in the International
#                           Tables for Crystallography, Vol. A.
#       'symop_ids'
#                           Array of symmetry operation identifiers.
#       'symops'
#                           Array of parsable strings giving the symmetry
#                           operations of the space group in algebraic form.
#       'ssg_name'
#                           Superspace-group symbol conforming to an
#                           alternative definition from that given in
#                           the 'ssg_name_IT' and 'ssg_name_WJJ' fields.
#       'ssg_name_IT'
#                           Superspace group symbol as given in International
#                           Tables for Crystallography, Vol. C.
#       'ssg_name_WJJ'
#                           Superspace-group symbol as given by de Wolff,
#                           Janssen & Janner (1981).
#       'ssg_symop_ids'
#                           Array of superspace group symmetry operation
#                           identifiers.
#       'ssg_symops'
#                           Array of parsable strings giving the symmetry
#                           operations of the superspace group in algebraic
#                           form.
#       'tags'
#                           A hash that records the names of the data items
#                           from which the space group data values were taken.
##
sub get_sg_data
{
    my ($data_block) = @_;

    my $sg_data_names = {
        'hall' => [
                    '_space_group_name_Hall',
                    '_space_group_name_hall',
                    '_symmetry_space_group_name_Hall',
                    '_symmetry_space_group_name_hall',
                  ],
        'hermann_mauguin' => [
                    '_space_group_name_H-M_alt',
                    '_space_group_name_h-m_alt',
                    '_symmetry_space_group_name_H-M',
                    '_symmetry_space_group_name_h-m',
                    '_space_group.name_H-M_full',
                    '_space_group.name_h-m_full'
                  ],
        'number' => [
                    '_space_group_IT_number',
                    '_space_group_it_number',
                    '_symmetry_Int_Tables_number',
                    '_symmetry_int_tables_number'
                  ],
        'symop_ids' => [
                    '_space_group_symop_id',
                    '_symmetry_equiv_pos_site_id'
                  ],
        'symops' => [
                    '_space_group_symop_operation_xyz',
                    '_symmetry_equiv_pos_as_xyz'
                  ],
        'ssg_name' => [
                    '_space_group_ssg_name'
                  ],
        'ssg_name_IT' => [
                    '_space_group_ssg_name_IT',
                    '_space_group_ssg_name_it'
                  ],
        'ssg_name_WJJ' => [
                    '_space_group_ssg_name_WJJ',
                    '_space_group_ssg_name_wjj'
                  ],
        'ssg_symop_ids' => [
                    '_space_group_symop_ssg_id'
                  ],
        'ssg_symops' => [
                    '_space_group_symop_ssg_operation_algebraic'
                  ]
    };

    my %looped_sg_data_types = map { $_ => $_ }
        qw( symop_ids symops ssg_symop_ids ssg_symops );

    my $values = $data_block->{'values'};
    my %sg_data;
    for my $info_type ( keys %{$sg_data_names} ) {
        foreach ( @{$sg_data_names->{$info_type}} ) {
            if ( exists $values->{$_} &&
                 !has_special_value($data_block, $_, 0) ) {
                $sg_data{$info_type} = $values->{$_};
                $sg_data{'tags'}{$info_type} = $_;
                if ( !exists $looped_sg_data_types{$info_type} ) {
                    $sg_data{$info_type} = $sg_data{$info_type}[0];
                }
                last;
            }
        }
    }

    return \%sg_data;
}

sub get_symmetry_operators($)
{
    my ( $dataset ) = @_;

    my $sg = get_sg_data($dataset);

    my $values = $dataset->{values};
    my $symops;

    if( exists $sg->{'symops'} ) {
        $symops = $sg->{'symops'}
    }

    my $sym_data = $symops;
    if( !defined $sym_data && defined $sg->{'hall'} ) {
        $sym_data = lookup_space_group('hall', $sg->{'hall'});
        if( !defined $sym_data ) {
            warn "WARNING, the '$sg->{'tags'}{'hall'}' data item value " .
                 "'$sg->{'hall'}' was not recognised as a space group name\n";
        }
    }

    if( !defined $sym_data && defined $sg->{'hermann_mauguin'} ) {
        $sym_data = lookup_space_group('hermann_mauguin', $sg->{'hermann_mauguin'});
        if( !defined $sym_data ) {
            warn "WARNING, the '$sg->{'tags'}{'hermann_mauguin'}' data item " .
                 "value '$sg->{'hermann_mauguin'}' was not recognised as a " .
                 "space group name\n";
        }
    }

    if( !defined $sym_data ) {
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

                $sym_data = lookup_space_group("hermann_mauguin", $h_m);

                if( !defined $sym_data ) {
                    warn "WARNING, the '$tag' data item value '$ssg_name' " .
                         "yielded H-M symbol '$h_m' which is not in our tables\n";
                } else {
                    last
                }
            }
        }
    }

    if ( !defined $symops && defined $sym_data ) {
        $symops = $sym_data->{'symops'}
    }

    if( !defined $sym_data ) {
        die 'ERROR, neither symmetry operator data item values, '
          . 'nor Hall space group name, '
          . 'nor Hermann-Mauguin space group name '
          . "could be processed to acquire symmetry operators\n";
    }

    return $symops;
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

sub lookup_space_group
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
            return $hash;
        }
    }
    return;
}

# Returns data block name. Original source data block name, if specified, is
# prefered. If not specified, current data block name is returned.
sub get_source_data_block_name
{
    my( $datablock, $options ) = @_;
    my $values = $datablock->{values};
    my $database = 'cod';
    if( $options && exists $options->{database} ) {
        $database = $options->{database};
    }

    if( exists $values->{"_${database}_data_source_block"} ) {
        return $values->{"_${database}_data_source_block"}[0];
    }
    if( exists $values->{"_[local]_${database}_data_source_block"} ) {
        return $values->{"_[local]_${database}_data_source_block"}[0];
    }

    return $datablock->{name};
}

sub get_formula_units_z
{
    my ( $data_block ) = @_;

    my $warnings = check_formula_units_z( $data_block );

    # TODO: currently floating-point values like "4.00" are treated as
    # errouneous, but they should probably be converted to integers with
    # a warning
    if ( @{$warnings} ) {
        foreach ( @$warnings ) { warn $_ . "\n"; };
        return;
    }

    return $data_block->{'values'}{'_cell_formula_units_Z'}[0];
}

# TODO: this subroutine should eventually be moved to the CIF::COD::Data::Check
# module, but for now it is kept here to avoid establishing an explicit
# interface
sub check_formula_units_z
{
    my ( $data_block ) = @_;

    my $data_name = '_cell_formula_units_Z';

    # TODO: these check are generic and should probably be moved
    # into a separate subroutine
    my $message;
    if ( !exists $data_block->{'values'}{$data_name} ) {
        $message = "the $data_name data item is missing";
    } elsif ( has_unknown_value( $data_block, $data_name, 0 ) ) {
        $message = "the $data_name item value is marked as unknown ('?')";
    } elsif ( has_inapplicable_value( $data_block, $data_name, 0 ) ) {
        $message = "the $data_name item value is marked as not applicable ('.')";
    };

    if ( !defined $message ) {
        if ( $data_block->{'values'}{$data_name}[0] !~
                                                /^\+?[0-9]*[1-9][0-9]*$/ ) {
            $message = "the $data_name data item value '" .
                       $data_block->{'values'}{$data_name}[0] .
                       '\' is not a natural number';
        }
    }

    return defined $message ? [ $message ] : [];
}

1;
