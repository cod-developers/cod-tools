#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Construct a common data structure, representing list of atoms in
#  a CIF file.
#**

package COD::CIF::Data::AtomList;

use strict;
use warnings;
use COD::CIF::Data qw( get_cell );
use COD::Spacegroups::Symop::Algebra qw( symop_invert symop_mul
                                         symop_vector_mul );
use COD::Spacegroups::Symop::Parse qw( string_from_symop
                                       symop_from_string );
use COD::Algebra::Vector qw( modulo_1 );
use COD::Fractional qw( symop_ortho_from_fract );
use COD::UserMessage qw( warning error prefix_dataname );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    atom_array_from_cif
    atom_is_disordered
    atoms_are_alternative
    copy_struct_deep
    dump_atoms_as_cif
    uniquify_atom_names
    extract_atom
);

#===============================================================#
# Extracts atom information from the CIF file.
#
# Accepts
#     atom_label - atom site label or atom site type symbol from the CIF file
#     values     - a hash where a data from the CIF file is stored
#     number     - a number of the current atom
#     f2o        - conversion matrix from fractional to Cartesian coordinates
#     filename   - name of analysed file
#     dataname   - name of analysed data block
#     options    - a hash with control options
#
# Returns a hash $atom:{
#                       label=>"C1",
#                       site_label=>"C1";
#                       chemical_type=>"C",
#                       atom_site_type_symbol = "C",
#                       coordinates_fract=>[1.0, 1.0, 1.0],
#                       unity_matrix_applied=>1,
#                       transform_matrices=>[ [
#                           [ 1, 0, 0, 0 ],
#                           [ 0, 1, 0, 0 ],
#                           [ 0, 0, 1, 0 ],
#                           [ 0, 0, 0, 1 ] ] ],
#                       assembly=>"A", # "."
#                       group=>"1", # "."
#                       }

sub extract_atom
{
    my($atom_label, $values, $number, $f2o, $filename, $dataname,
       $options) = @_;

    $dataname = prefix_dataname($dataname);

    $options = {} unless $options;

    my %atom_info;
    my @atom_xyz;

    for my $cif_fract ( "_atom_site_fract_x",
                        "_atom_site_fract_y",
                        "_atom_site_fract_z" ) {
        if( $values->{$cif_fract}[$number] eq '?' &&
            $options->{stop_if_coordinates_unknown} ) {
            return undef;
        }
        push(@atom_xyz, $values->{$cif_fract}[$number]);
        $atom_xyz[-1] =~ s/\(\d+\)$//;
    }

    if( $options->{modulo_1} ) {
        @atom_xyz = map { modulo_1($_) } @atom_xyz;
    }

    $atom_info{"coordinates_fract"}     = \@atom_xyz;
    $atom_info{"name"}                  = $atom_label;
    $atom_info{"site_label"}            = $atom_label;
    $atom_info{"cell_label"}            = $atom_label;
    $atom_info{"index"}                 = $number;
    $atom_info{"symop"}                 =
      [
        [ 1, 0, 0, 0 ],
        [ 0, 1, 0, 0 ],
        [ 0, 0, 1, 0 ],
        [ 0, 0, 0, 1 ]
      ];
    $atom_info{"symop_id"}              = 1;
    $atom_info{"unity_matrix_applied"}  = 1;
    $atom_info{"translation_id"}        = "555";
    $atom_info{"translation"}           = [ 0, 0, 0 ];
    if( $options->{symop_list} ) {
        $atom_info{"symop_list"} = $options->{symop_list};
    }

    if( $options->{skip_dummy_atoms} &&
        defined $values->{_atom_site_calc_flag} &&
        $values->{_atom_site_calc_flag}[$number] eq 'dum' ) {
        return undef;
    }

    $atom_info{f2o} = $f2o;
    if( $atom_xyz[0] eq '.' &&
        $atom_xyz[1] eq '.' &&
        $atom_xyz[2] eq '.' &&
        $options->{copy_dummy_coordinates} ) {
        $atom_info{coordinates_ortho} = [ '.', '.', '.' ];
    } else {
        $atom_info{coordinates_ortho} =
            symop_vector_mul( $f2o, \@atom_xyz );
    }

    my $atom_type;

    if( exists $values->{_atom_site_type_symbol} &&
        defined $values->{_atom_site_type_symbol}[$number] &&
        $values->{_atom_site_type_symbol}[$number] ne '?' ) {
        $atom_type = $values->{_atom_site_type_symbol}[$number];
        $atom_info{atom_site_type_symbol} = $atom_type;
        if( $atom_type =~ m/^([A-Za-z]{1,2})/ ) {
            $atom_type = ucfirst( lc( $1 ));
        }
    } else {
        if( $values->{_atom_site_label}[$number] =~
            m/^([A-Za-z]{1,2})/ ) {
            $atom_type = ucfirst( lc( $1 ));
        } elsif( $options->{continue_on_unknown_atom_type} ) {
            warning( $0, $filename, $dataname,
                     "could not determine atom type for atom " .
                     "'$values->{_atom_site_label}[$number]'", undef );
        } else {
            die( "could not determine atom type for atom " .
                 "'$values->{_atom_site_label}[$number]'" );
        }
    }

    $atom_info{chemical_type} = $atom_type;
    $atom_info{assembly} = ".";
    $atom_info{group}    = ".";

    my %to_copy_atom_site = (
        _atom_site_disorder_assembly     => 'assembly',
        _atom_site_disorder_group        => 'group',
        _atom_site_occupancy             => 'atom_site_occupancy',
        _atom_site_U_iso_or_equiv        => 'atom_site_U_iso_or_equiv',
        _atom_site_symmetry_multiplicity => 'multiplicity',
        _atom_site_attached_hydrogens    => 'attached_hydrogens',
        _atom_site_refinement_flags      => 'refinement_flags',
        _atom_site_refinement_posn       => 'refinement_flags_position',
        _atom_site_refinement_adp        => 'refinement_flags_adp',
        _atom_site_refinement_occupancy  => 'refinement_flags_occupancy',
        _atom_site_calc_flag             => 'calc_flag',
    );

    my %to_copy_cod_molecule = (
        _cod_molecule_atom_orig_label    => 'original_label',
        _cod_molecule_atom_assembly      => 'assembly',
        _cod_molecule_atom_group         => 'group',
        _cod_molecule_atom_mult          => 'multiplicity',
        _cod_molecule_atom_mult_ratio    => 'multiplicity_ratio',
        _cod_molecule_atom_symop_id      => 'symop_id',
    );

    for my $tag (keys %to_copy_atom_site) {
        next if !exists $values->{$tag};
        $atom_info{$to_copy_atom_site{$tag}} = $values->{$tag}[$number];
    }

    if( $options->{remove_precision} ) {
        for my $key (qw( atom_site_occupancy atom_site_U_iso_or_equiv )) {
            next if !exists $atom_info{$key};
            $atom_info{$key} =~ s/\([0-9]+\)$//;
        }
    }

    if( $options->{concat_refinement_flags} ) {
        my %refinement_flags;
        for my $key (qw( refinement_flags
                         refinement_flags_posn
                         refinement_flags_adp
                         refinement_flags_occupancy )) {
            next if !exists $atom_info{$key};
            next if $atom_info{$key} eq '?' || $atom_info{$key} eq '.';
            map { $refinement_flags{$_} = 1 }
                split '', $atom_info{$key};
            delete $atom_info{$key};
        }
        if( %refinement_flags ) {
            $atom_info{refinement_flags} =
                join( '', sort keys %refinement_flags );
        }
    }

    # Some of _cod_molecule_* tags override tags from _atom_site_* loop,
    # thus former have to be copied AFTER the former.

    if( $options->{use_cod_molecule_tags} ) {

        for my $tag (keys %to_copy_cod_molecule) {
            next if !exists $values->{$tag};
            $atom_info{$to_copy_cod_molecule{$tag}} = $values->{$tag}[$number];
        }

        my @transform_matrices;
        if( defined $values->{_cod_molecule_atom_symop_xyz} ) {
            @transform_matrices = ( $values->{_cod_molecule_atom_symop_xyz}[$number] );
        }

        if( defined $values->{_cod_molecule_transform_label} &&
            defined $values->{_cod_molecule_transform_symop} ) {
            for my $i (0..$#{$values->{_cod_molecule_transform_label}}) {
                if( $values->{_cod_molecule_transform_label}[$i] ne
                    $atom_label ) {
                    next
                }
                my $symop = $values->{_cod_molecule_transform_symop}[$i];
                if( @transform_matrices ) {
                    my $orig_symop = symop_from_string( $transform_matrices[0] );
                    my $symop_mat = symop_from_string( $symop );
                    my $product = symop_mul( $orig_symop, $symop_mat );
                    $symop = string_from_symop( $product );
                }
                push( @transform_matrices, $symop );
            }
        }

        if( @transform_matrices ) {
            $atom_info{transform_matrix} = [
                map { symop_from_string( $_ ) }
                    @transform_matrices
            ];
            $atom_info{transform_matrix_inv} = [
                map { symop_invert( $_ ) }
                    @{$atom_info{transform_matrix}}
            ];
        }

        if( defined $values->{_cod_molecule_atom_transl_x} &&
            defined $values->{_cod_molecule_atom_transl_y} &&
            defined $values->{_cod_molecule_atom_transl_z} ) {
            $atom_info{translation} = [
                $values->{_cod_molecule_atom_transl_x}[$number],
                $values->{_cod_molecule_atom_transl_y}[$number],
                $values->{_cod_molecule_atom_transl_z}[$number],
            ];
        }
    }

    if( !exists $atom_info{atom_site_occupancy} &&
        $options->{assume_full_occupancy} ) {
        $atom_info{atom_site_occupancy} = 1;
    }

    return \%atom_info;
}

# ============================================================================ #
# Gets atom descriptions, as used in this program, from a CIF datablock.
#
# Returns an array of
#
#   $atom_info = {
#                   site_label=>"C1",
#                   name=>"C1_2",
#                   chemical_type=>"C",
#                   atom_site_type_symbol = "C",
#                   coordinates_fract=>[1.0, 1.0, 1.0],
#                   unity_matrix_applied=>1,
#                   assembly=>"A", # "."
#                   group=>"1", # "."
#                   multiplicity=>"1",
#                   multiplicity_ratio=>"1",
#              }
#
sub atom_array_from_cif($$$@)
{
    my( $datablock, $atom_properties, $filename, $options ) = @_;

    $options = {} unless $options;

    my $values = $datablock->{values};
    my $dataname = prefix_dataname($datablock->{name});

    # Get the unit cell information and construct the fract->ortho and
    # ortho->fract conversion matrices:

    my @cell = get_cell( $values, $filename, $datablock->{name} );
    my $f2o = symop_ortho_from_fract( @cell );

    if( $options->{homogenize_transform_matrices} ) {
        push( @{$f2o->[0]}, 0 );
        push( @{$f2o->[1]}, 0 );
        push( @{$f2o->[2]}, 0 );
        push( @$f2o, [0,0,0,1] );
    }

    # Determine which atom site label tag is present and which can be
    # used for identifying atoms:

    my $atom_site_tag;

    if( exists $values->{"_atom_site_label"} ) {
        $atom_site_tag = "_atom_site_label";
    } elsif( exists $values->{"_atom_site_type_symbol"} ) {
        $atom_site_tag = "_atom_site_type_symbol";

        error( $0, $filename, $dataname,
               "_atom_site_label tag was not found",
               "a serial number will be appended " .
               "to _atom_site_type_symbol to make atom labels" );
    } else {
        error( $0, $filename, $dataname,
               "neither _atom_site_type_symbol nor _atom_site_label " .
               "were found", undef );
        return undef;
    }

    my $atom_labels = $values->{$atom_site_tag};

    my @atom_list;

    for (my $i = 0; $i < @{$atom_labels}; $i++)
    {
        if( $options->{exclude_zero_occupancies} &&
            defined $values->{_atom_site_occupancy} ) {
            my $occupancy = $values->{_atom_site_occupancy}[$i];
            $occupancy =~ s/\(\d+\)$//; # remove precision
            if( $occupancy eq "?" || $occupancy eq "." ||
                $occupancy == 0.0 ) {
                next;
            }
        }

        my $label;
        if ( $atom_site_tag eq "_atom_site_type_symbol" ) {
            $label = $values->{$atom_site_tag}[$i] . $i;
        } else {
            $label = $values->{$atom_site_tag}[$i];
        }

        my $atom_info = extract_atom( $label, $values, $i, $f2o,
                                      $filename, $datablock->{name},
                                      $options );

        # Some of the code used to return undef from extract_atom in case
        # an atom has to be skipped, so this is silently done in order to
        # stay compatible with the code.
        next if !defined $atom_info;

        if( exists $values->{_atom_site_symmetry_multiplicity} &&
            $values->{_atom_site_symmetry_multiplicity}[$i] ne '?' &&
            $values->{_atom_site_symmetry_multiplicity}[$i] ne '.' ) {
            $atom_info->{_atom_site_symmetry_multiplicity} =
                $values->{_atom_site_symmetry_multiplicity}[$i];
        }

        if (exists $atom_properties->{$atom_info->{"chemical_type"}} ||
            $options->{ignore_unknown_chemical_types} ) {
            push( @atom_list, $atom_info );
        } else {
            my $message = "unknown chemical type '" .
                $atom_info->{chemical_type} . "'";

            if( $options->{continue_on_errors} ) {
                warning( $0, $filename, $dataname, $message, undef );
            } else {
                error( $0, $filename, $dataname, $message, undef );
                exit(1);
            }
        }
    }

    if( $options->{uniquify_atom_names} ) {
        return uniquify_atom_names( \@atom_list,
                                    $options->{uniquify_atoms},
                                    $filename,
                                    $datablock->{name});
    } else {
        return \@atom_list;
    }
}

# ============================================================================ #
# Accepts an array of
#
#   $atom_info = {
#                   site_label=>"C1",
#                   name=>"C1_2",
#                   chemical_type=>"C",
#                   coordinates_fract=>[1.0, 1.0, 1.0],
#                   unity_matrix_applied=>1,
#                   assembly=>"A", # "."
#                   group=>"1", # "."
#              }
#
sub uniquify_atom_names($$$$)
{
    my ($init_atoms, $uniquify_atoms, $filename, $dataname) = @_;

    my $max_label_suffix = 30000; # Maximum number to be appened to labels 
                                  # when trying to produce unique names.

    $dataname = prefix_dataname($dataname);

    my @checked_initial_atoms;

    my %used_labels;
    my %labels_to_be_renamed;

    foreach my $atom (@{$init_atoms})
    {
        my $atom_copy = copy_atom( $atom );
        my $label = $atom->{name};

        push( @checked_initial_atoms, $atom_copy );

        if( ! exists $used_labels{$label} ) {
            $used_labels{$label}{atoms} = [ $atom_copy ];
        } else {
            push( @{$used_labels{$label}{atoms}}, $atom_copy );
            warning( $0, $filename, $dataname,
                     "atom label '$label' is not unique", undef );

            $labels_to_be_renamed{$label} ++;
        }
        $used_labels{$label}{count} ++;
    }

    if( $uniquify_atoms )
    {
        foreach my $label (sort keys %labels_to_be_renamed)
        {
            foreach my $renamed_atom (@{$used_labels{$label}{atoms}}) {
                my $id = 0;
                while( exists $used_labels{$label . "_" .$id} &&
                       $id <= $max_label_suffix ) {
                    $id ++;
                }
                if( $id > $max_label_suffix ) {
                    error( $0, $filename, $dataname,
                           "could not generate unique atom name for ".
                           "atom '$label', even after $id iterations", undef );
                }
                my $new_label = $label . "_" . $id;
                warning( $0, $filename, $dataname,
                         "renaming atom '$label' " .
                         "to '" . $new_label . "'", undef );
                $renamed_atom->{name}       = $new_label;
                $renamed_atom->{site_label} = $new_label;
                $used_labels{$new_label}{count} ++;
            }
        }
    }

    return \@checked_initial_atoms;
}

#===============================================================#
# Copies atom and returns the same instance of it (different object, same props)

# Accepts a hash $atom_info = {
#                       name=>"C1_2",
#                       site_label=>"C1",
#                       chemical_type=>"C",
#                       coordinates_fract=>[1.0, 1.0, 1.0],
#                       coordinates_ortho=>[5.0, -1.3, 1.7],
#                       transform_matrices=>[ [
#                           [ 1, 0, 0, 0 ],
#                           [ 0, 1, 0, 0 ],
#                           [ 0, 0, 1, 0 ],
#                           [ 0, 0, 0, 1 ] ] ],
#                       unity_matrix_applied=>1,
#                       symop_id=>1
#                       assembly=>"A", # "."
#                       group=>"1", # "."
#                       }

# Returns a hash $new_atom_info = {
#                       name=>"C1_2",
#                       site_label=>"C1",
#                       chemical_type=>"C",
#                       coordinates_fract=>[1.0, 1.0, 1.0],
#                       coordinates_ortho=>[5.0, -1.3, 1.7],
#                       transform_matrices=>[ [
#                           [ 1, 0, 0, 0 ],
#                           [ 0, 1, 0, 0 ],
#                           [ 0, 0, 1, 0 ],
#                           [ 0, 0, 0, 1 ] ] ],
#                       unity_matrix_applied=>1,
#                       symop_id=>1,
#                       assembly=>"A", # "."
#                       group=>"1", # "."
#                       }
sub copy_atom
{
    my($old_atom) = @_;

    if( ref $old_atom ne "HASH" ) {
        use Carp;
        croak;
    }

    my @shallow_copied_keys = qw( symop_list f2o site_symops symop );

    my $atom_copy = copy_struct_deep( $old_atom,
                                      { excluded_hash_keys =>
                                        \@shallow_copied_keys } );

    for my $key ( @shallow_copied_keys ) {
        next if !exists $old_atom->{$key};
        $atom_copy->{$key} = $old_atom->{$key};
    }

    return $atom_copy;
}

#===============================================================#
# Performs deep copying of structure passed via reference
sub copy_struct_deep
{
    my( $struct, $options ) = @_;

    if(      !ref $struct ) {
        return $struct;
    } elsif( ref $struct eq "ARRAY" ) {
        return [ map( copy_struct_deep($_), @$struct ) ];
    } elsif( ref $struct eq "HASH" ) {
        $options = {} unless defined $options;

        my %excluded_hash_keys;
        if( exists $options->{excluded_hash_keys} ) {
            %excluded_hash_keys = map { $_ => 1 }
                                      @{ $options->{excluded_hash_keys} };
        }

        return { map { $_ => copy_struct_deep( $struct->{$_} ) }
                 map { (exists $excluded_hash_keys{$_}) ? () : $_ }
                     keys %$struct };
    } else {
        die "deep copy failed: 'copy_struct_deep' does not know " .
            "how to copy object '" . ref( $struct ) . "'";
    }
}

#===============================================================#
# Returns true if atom is disordered, false otherwise
sub atom_is_disordered($)
{
    my( $atom ) = @_;
    return exists $atom->{assembly} &&
           exists $atom->{group} &&
           $atom->{group} ne '.';
}

#===============================================================#
# Check whether atoms belong to the same disorder assembly and
# are alternative (belong to different groups of same assembly).
sub atoms_are_alternative($$)
{
    my( $atom1, $atom2 ) = @_;
    return atom_is_disordered( $atom1 ) &&
           atom_is_disordered( $atom2 ) &&
           $atom1->{assembly} eq $atom2->{assembly} &&
           $atom1->{group} ne $atom2->{group};
}

sub dump_atoms_as_cif
{
    my ($datablock_name, $atom_list, $cell) = @_;

    local $\ = "\n";

    print "data_", $datablock_name;

    print "_symmetry_space_group_name_H-M ", "'P 1'";
    print "_cell_length_a ", $$cell[0] if defined $$cell[0];
    print "_cell_length_b ", $$cell[1] if defined $$cell[1];
    print "_cell_length_c ", $$cell[2] if defined $$cell[2];

    print "_cell_angle_alpha ", $$cell[3] if defined $$cell[3];
    print "_cell_angle_beta  ", $$cell[4] if defined $$cell[4];
    print "_cell_angle_gamma ", $$cell[5] if defined $$cell[5];

    print "loop_";
    print "_atom_site_label";
    print "_atom_site_fract_x";
    print "_atom_site_fract_y";
    print "_atom_site_fract_z";

    for my $atom (@$atom_list) {
        print
            $atom->{name}, " ",
            $atom->{coordinates_fract}[0], " ",
            $atom->{coordinates_fract}[1], " ",
            $atom->{coordinates_fract}[2];
    }
}

1;
