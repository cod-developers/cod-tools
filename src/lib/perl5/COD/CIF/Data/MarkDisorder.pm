#------------------------------------------------------------------------------
#$Author$
#$Date$
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#* Mark disorder in CIF files judging by distance and occupancy.

package COD::CIF::Data::MarkDisorder;

use strict;
use warnings;
use COD::AtomBricks qw( build_bricks get_atom_index get_search_span );
use COD::CIF::ChangeLog qw( append_changelog_to_single_item );
use COD::CIF::Data qw( get_cell get_symmetry_operators );
use COD::CIF::Data::AtomList qw( atoms_are_alternative atom_array_from_cif );
use COD::CIF::Data::SymmetryGenerator qw(
    symop_generate_atoms
);
use COD::CIF::Tags::Manage qw( set_tag set_loop_tag );
use COD::Fractional qw( symop_ortho_from_fract );
use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul );
use COD::Spacegroups::Symop::Parse qw(
    symop_from_string
    symop_string_canonical_form
);
use COD::Algebra::Vector qw( distance );
use List::Util qw( any first sum uniqstr );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    mark_disorder
);

##
# Find alternatives among CIF atoms.
#
# @param $atom_list
#       Reference to a CIF atom array, as returned by
#       COD::CIF::Data::AtomList::initial_atoms().
# @param $bricks
#       Reference to bricks array, as returned by build_bricks().
# @param $f2o
#       Reference to an orthogonalization matrix.
# @param $options
#       Reference to an option hash. The following options are recognised:
#       {
#         # Exclude atoms with zero occupancies.
#         # Default: '1'.
#           'exclude_zero_occupancies' => 1,
#         # Ignore atom occupancies when detecting compositional disorder.
#         # Default: '0'.
#           'ignore_occupancies' => 0,
#         # Maximum distance between atoms to be considered as a same site.
#         # Default: '0.000001'.
#           'same_site_distance_sensitivity'  => 0.000001,
#         # Maximum difference of occupancy sum from 1 for atoms to be
#         # considered compositionally disordered.
#         # Default: '0.01'
#           'same_site_occupancy_sensitivity' => 0.01,
#       }
# @return $alternatives
#       Reference to a hash describing newly assigned disorder assemblies
#       and groups. Atom indices are used as keys, and values are array
#       references with two values, disorder assembly number and group,
#       correspondingly:
#       {
#         0 => [ 0, 1 ],
#       }
##
sub get_alternatives
{
    my( $atom_list, $bricks, $f2o, $options ) = @_;

    $options = {} unless $options;
    my $default_options = {
        exclude_zero_occupancies => 1,
        ignore_occupancies => 0,
        same_site_distance_sensitivity  => 0.000001,
        same_site_occupancy_sensitivity => 0.01,
    };
    for my $key (keys %$default_options) {
        next if exists $options->{$key};
        $options->{$key} = $default_options->{$key};
    }

    if( @{$atom_list} != uniqstr map { $_->{name} } @{$atom_list} ) {
        die 'ERROR, cannot process structures with non-unique atom names', "\n";
    }

    my @assemblies;
    my %in_assembly;
    my %index_map = map { $atom_list->[$_]{name} => $_ } 0..$#{$atom_list};
    my %shown_messages;

    for my $site_1 (@$atom_list) {
        # Skipping dummy atoms
        next if $site_1->{coordinates_fract}[0] eq '.' ||
                $site_1->{coordinates_fract}[1] eq '.' ||
                $site_1->{coordinates_fract}[2] eq '.';

        my $atom_in_unit_cell_coords_ortho =
            symop_vector_mul( $f2o, $site_1->{coordinates_fract} );

        my ($i_init, $j_init, $k_init) =
            get_atom_index( $bricks, @{$atom_in_unit_cell_coords_ortho});

        my( $min_i, $max_i, $min_j, $max_j, $min_k, $max_k ) =
            get_search_span( $bricks, $i_init, $j_init, $k_init );

        my $atom_1 = $site_1;
        if( !atom_is_from_AU( $atom_1 ) ) {
            $atom_1 = first { $_->{name} eq $site_1->{site_label} }
                           @{$atom_list};
        }
        my $atom_1_index = $index_map{$atom_1->{name}};
        my $site_1_index = $index_map{$site_1->{name}};

        for my $i ($min_i .. $max_i) {
        for my $j ($min_j .. $max_j) {
        for my $k ($min_k .. $max_k) {
            for my $site_2 ( @{$bricks->{atoms}[$i][$j][$k]} ) {
                my $atom_coords_ortho = $site_2->{coordinates_ortho};

                my $atom_2 = $site_2;
                if( !atom_is_from_AU( $atom_2 ) ) {
                    $atom_2 = first { $_->{name} eq $site_2->{site_label} }
                                   @{$atom_list};
                }
                my $atom_2_index = $index_map{$atom_2->{name}};
                my $site_2_index = $index_map{$site_2->{name}};

                next if $site_1_index >= $site_2_index;
                next if $atom_1_index == $atom_2_index;
                next if !exists $site_2->{'atom_site_occupancy'};
                next if $site_2->{'atom_site_occupancy'} eq '?';
                next if $site_2->{'atom_site_occupancy'} eq '.';
                next if $site_2->{'atom_site_occupancy'} == 0 &&
                        $options->{'exclude_zero_occupancies'};

                my $dist = distance( $atom_in_unit_cell_coords_ortho,
                                     $atom_coords_ortho );
                next if $dist > $options->{same_site_distance_sensitivity};

                # Skipping atoms already marked as compositionally
                # disordered
                next if atoms_are_alternative( $atom_1, $atom_2 );

                # Reporting overlapping disordered atoms
                my @disordered_atoms = grep { atom_is_disordered_strict( $_ ) }
                                            ( $atom_1, $atom_2 );
                if( @disordered_atoms ) {
                    my $message =
                        'WARNING, atoms ' .
                        join( ', ', sort map { "'$_'" }
                                         map { $_->{name} }
                                             ( $atom_1, $atom_2 ) ) .
                        ' share the same site, but ' .
                        (@disordered_atoms == 2
                            ? 'both are '
                            : "'$disordered_atoms[0]->{name}' is ") .
                        'already marked as disordered -- atoms will not be ' .
                        'marked as sharing the same disordered site' . "\n";
                    warn $message unless $shown_messages{$message};
                    $shown_messages{$message} = 1;
                    next;
                }

                if( !exists $in_assembly{$atom_1_index} &&
                    !exists $in_assembly{$atom_2_index} ) {
                    # Creating new assembly
                    $in_assembly{$atom_1_index} = scalar @assemblies;
                    $in_assembly{$atom_2_index} = scalar @assemblies;
                    push @assemblies, [ $atom_1_index, $atom_2_index ];
                } elsif( exists $in_assembly{$atom_1_index} &&
                         exists $in_assembly{$atom_2_index} ) {
                    my $assembly1 = $in_assembly{$atom_1_index};
                    my $assembly2 = $in_assembly{$atom_2_index};
                    next if $assembly1 == $assembly2;

                    # Merging two assemblies into a new one
                    my @new_assembly = ( @{$assemblies[$assembly1]},
                                         @{$assemblies[$assembly2]} );
                    foreach( @{$assemblies[$assembly1]},
                             @{$assemblies[$assembly2]} ) {
                        $in_assembly{$_} = scalar @assemblies;
                    }

                    # Emptying merged assemblies -- empty ones will be
                    # skipped below
                    $assemblies[$assembly1] = [];
                    $assemblies[$assembly2] = [];
                    push @assemblies, \@new_assembly;
                } else {
                    # Joining one atom to the assembly
                    if( exists $in_assembly{$atom_1_index} ) {
                        push @{$assemblies[$in_assembly{$atom_1_index}]},
                             $atom_2_index;
                        $in_assembly{$atom_2_index} = $in_assembly{$atom_1_index};
                    } else {
                        push @{$assemblies[$in_assembly{$atom_2_index}]},
                             $atom_1_index;
                        $in_assembly{$atom_1_index} = $in_assembly{$atom_2_index};
                    }
                }
            }
        }}}
    }

    my $assembly_nr = 0;
    my %assemblies_now;
    for my $assembly (@assemblies) {
        next unless @$assembly;
        my $occupancy_sum =
            sum( 0.0, map { $atom_list->[$_]{atom_site_occupancy} }
                          @$assembly );
        if( abs( $occupancy_sum - 1 ) >
            $options->{same_site_occupancy_sensitivity} &&
            !$options->{ignore_occupancies} ) {
            my @names = sort map { $atom_list->[$_]{name} } @$assembly;
            warn 'WARNING, atoms ' . join( ', ', map { "'$_'" } @names ) .
                 ' share the same site, but their occupancies add up to ' .
                 $occupancy_sum . ' instead of 1 -- atoms will not be ' .
                 'marked as sharing the same disordered site' . "\n";
            next;
        }

        my $group_nr = 1;
        foreach (sort {$a <=> $b} @$assembly) {
            $assemblies_now{$_} = [ $assembly_nr, $group_nr ];
            $group_nr++;
        }
        $assembly_nr++;
    }

    return \%assemblies_now;
}

##
# Find and mark disorder in a given CIF data block overwriting old values.
#
# @param $dataset
#       Reference to a CIF data block as returned by the COD::CIF::Parser.
# @param $atom_properties
#       Reference to an array of atom properties as in COD::AtomProperties.
# @param $options
#       Reference to an option hash. The following options are recognised:
#       {
#         # Size of a brick in angstroms as generated using build_bricks().
#         # Default: '1'.
#           'brick_size' => 1,
#         # Exclude atoms with zero occupancies.
#         # Default: '1'.
#           'exclude_zero_occupancies' => 1,
#         # Ignore atom occupancies when detecting compositional disorder.
#         # Default: '1'.
#           'ignore_occupancies' => 0,
#         # Record the changes in '_cod_depositor_comments' CIF data item.
#         # Default: '1'.
#           'messages_to_depositor_comments' => 1,
#         # Do not leave dot ('.') assembly in the resulting CIF.
#         # Default: '1'.
#           'no_dot_assembly' => 1,
#         # Signature string of the entity that carried out the changes.
#         # The signature will be appended to the changelog in
#         # the '_cod_depositor_comments' CIF data item.
#         # Default: ''.
#           'depositor_comments_signature' =>
#                   'Id: cif_mark_disorder 8741 2021-04-28 16:48:47Z user'
#         # Reconstruct symmetry before looking for unmarked disorder.
#         # Default: '1'.
#           'reconstruct_symmetry' => 1,
#         # Warn about marked disorder.
#         # Default: '1'.
#           'report_marked_disorders' => 1,
#         # Maximum distance between atoms to be considered as a same site.
#         # Default: '0.000001'.
#           'same_site_distance_sensitivity' => 0.000001,
#         # Maximum difference of occupancy sum from 1 for atoms to be
#         # considered compositionally disordered.
#         # Default: '0.01'
#           'same_site_occupancy_sensitivity' => 0.01,
#       }
##
sub mark_disorder
{
    my( $dataset, $atom_properties, $options ) = @_;
    my $values = $dataset->{values};

    $options = {} unless $options;
    my $default_options = {
        brick_size => 1,
        exclude_zero_occupancies => 1,
        ignore_occupancies => 0,
        messages_to_depositor_comments => 1,
        no_dot_assembly => 1,
        reconstruct_symmetry => 0,
        report_marked_disorders => 1,
        same_site_distance_sensitivity => 0.000001,
        same_site_occupancy_sensitivity => 0.01,
        uniquify_atoms => 0,
    };
    for my $key (keys %$default_options) {
        next if exists $options->{$key};
        $options->{$key} = $default_options->{$key};
    }

    my $atom_array_from_cif_options = {
        allow_unknown_chemical_types => 1,
        assume_full_occupancy => 1,
        atom_properties => $atom_properties,
        exclude_dummy_coordinates => 1,
        exclude_unknown_coordinates => 1,
        remove_precision => 1,
        uniquify_atom_names => 1,
        uniquify_atoms => $options->{uniquify_atoms},
    };

    my @sym_operators;
    if( $options->{reconstruct_symmetry} ) {
        # Create a list of symmetry operators:
        my $sym_data = get_symmetry_operators( $dataset );
        @sym_operators = map { symop_from_string($_) } @{$sym_data};
        my $symop_list = { symops => \@sym_operators,
                           symop_ids => {} };
        for (my $i = 0; $i < @{$sym_data}; $i++) {
            $symop_list->{symop_ids}
                         {symop_string_canonical_form($sym_data->[$i])} = $i;
        }
        $atom_array_from_cif_options->{symop_list} = $symop_list;
    }

    # Extract atoms fract coordinates
    my $atom_list =
        atom_array_from_cif( $dataset, $atom_array_from_cif_options );

    if( $options->{reconstruct_symmetry} ) {
        $atom_list = symop_generate_atoms( \@sym_operators,
                                           $atom_list,
                                           { append_atoms_mapping_to_self => 0 } );
    }

    my $bricks = build_bricks( $atom_list, $options->{brick_size} );

    # Get cell angles(alpha, beta, gamma) and lengths(a, b, c)
    my @cell = get_cell( $values );

    # Make a matrix to convert from fractional coordinates to
    # orthogonal:
    my $f2o = symop_ortho_from_fract(@cell);

    my $alternatives =
        get_alternatives( $atom_list,
                          $bricks,
                          $f2o,
                          { same_site_distance_sensitivity =>
                                $options->{same_site_distance_sensitivity},
                            same_site_occupancy_sensitivity =>
                                $options->{same_site_occupancy_sensitivity},
                            exclude_zero_occupancies =>
                                $options->{exclude_zero_occupancies},
                            ignore_occupancies =>
                                $options->{ignore_occupancies} } );

    my @messages;

    # Rename dot assembly.
    my @dot_assembly_atoms =
        grep { atom_is_from_AU( $_ ) &&
               exists $_->{assembly} && $_->{assembly} eq '.'  &&
               exists $_->{group}    && $_->{group} ne '.' }
             @$atom_list;
    if( $options->{no_dot_assembly} && @dot_assembly_atoms ) {
        my $used_assembly_names = get_assembly_names( $atom_list );
        if( @{$used_assembly_names} || %{$alternatives} ) {

            my ( $new_name ) = generate_additional_assembly_names( $used_assembly_names );
            foreach (@dot_assembly_atoms) {
                $_->{assembly} = $new_name;
            }

            my $message = 'disorder assembly \'.\' containing atom(s) ' .
                          join( ', ', sort map { "'$_->{name}'" } @dot_assembly_atoms ) .
                          " was renamed to '$new_name'";
            push @messages, $message;
            warn "NOTE, $message\n";
        }
    }

    # Mark newly detected disorder assemblies.
    my $new_assembly_messages =
        assign_new_disorder_assemblies( $atom_list,
                                        $alternatives,
                                        $options );
    if (@{$new_assembly_messages}) {
        if( $options->{report_marked_disorders} ) {
            for my $message (@{$new_assembly_messages}) {
                warn "NOTE, $message\n";
            }
        }
        warn 'NOTE, '. scalar( @{$new_assembly_messages} ) . ' site(s) ' .
             'were marked as disorder assemblies' . "\n";
        push @messages, @{$new_assembly_messages};
    }

    # Modify the CIF data structure.
    if( @messages ) {
        my $atom_site_tag;
        if( exists $values->{'_atom_site_label'} ) {
            $atom_site_tag = '_atom_site_label';
        } else {
            $atom_site_tag = '_atom_site_type_symbol';
        }

        my @assemblies = map  { $_->{'assembly'} }
                         grep { atom_is_from_AU( $_ ) }
                              @{$atom_list};
        my @groups = map  { $_->{'group'} }
                     grep { atom_is_from_AU( $_ ) }
                          @{$atom_list};

        set_loop_tag( $dataset,
                      '_atom_site_disorder_assembly',
                      $atom_site_tag,
                      \@assemblies );
        set_loop_tag( $dataset,
                      '_atom_site_disorder_group',
                      $atom_site_tag,
                      \@groups );

        if( $options->{messages_to_depositor_comments} ) {
            append_changelog_to_single_item(
                $dataset,
                [ map { ucfirst $_ . '.' } @messages ],
                { signature => $options->{depositor_comments_signature} } );
        }
    }

    return;
}

##
# Assigns previously unmarked disorder assemblies to the atoms from
# the atom list. Modifies the input $atom_list data structure.
#
# @param $atom_list
#       Reference to a CIF atom array, as returned by
#       COD::CIF::Data::AtomList::initial_atoms().
# @param $alternatives
#       Reference to a data structure that describes unmarked
#       disordered sites as returned by get_alternatives().
# @param $options
#       Reference to an option hash. The following options are recognised:
#       {
#         # Do not produce dot ('.') assembly.
#         # Default: '1'.
#           'no_dot_assembly' => 1,
#       }
# @return $messages
#       Reference to an array of log messages describing each newly
#       assigned disorder assembly.
##
sub assign_new_disorder_assemblies
{
    my ($atom_list, $alternatives, $options) = @_;

    $options = {} unless $options;

    my @new_assemblies;
    for my $atom_index (keys %{$alternatives}) {
        my $assembly_nr = $alternatives->{$atom_index}[0];
        push @{$new_assemblies[$assembly_nr]}, $atom_index;
    }

    my $used_assembly_names = get_assembly_names($atom_list);
    my @assembly_names =
        generate_additional_assembly_names( $used_assembly_names, scalar @new_assemblies );

    # If there is a single assembly in the whole file after generating new
    # ones, and dot assembly is unwanted, a different assembly name is
    # generated.
    if( $options->{no_dot_assembly} &&
        !@$used_assembly_names &&
        @new_assemblies == 1 ) {
        @assembly_names =
            generate_additional_assembly_names( \@assembly_names );
    }

    # Add assembly and group symbols to the atoms.
    for my $index (0..$#{$atom_list}) {
        my $atom = $atom_list->[$index];
        if( exists $alternatives->{$index} ) {
            $atom->{'assembly'} = $assembly_names[$alternatives->{$index}[0]];
            $atom->{'group'} = $alternatives->{$index}[1];
        } else {
            $atom->{'assembly'} = '.' unless exists $atom->{'assembly'};
            $atom->{'group'} = '.' unless exists $atom->{'group'};
        }
    }

    my @messages;
    if( @new_assemblies ) {
        for my $assembly (@new_assemblies) {
            my @names = sort map { $atom_list->[$_]{'name'} } @{$assembly};
            my $site_name = $assembly_names[$alternatives->{$assembly->[0]}[0]];
            push @messages,
                 'atoms ' . ( join ', ', map { "'$_'" } @names ) .
                 ' were marked as sharing the same disordered site ' .
                 "'$site_name' based on their atomic coordinates and " .
                 'occupancies';
        }
    }

    return \@messages;
}

##
# Returns the codes of all disorder assemblies that are assigned
# to at least one atom.
#
# @input $atom_list
#       Reference to a CIF atom array, as returned by
#       COD::CIF::Data::AtomList::initial_atoms().
# @return $assembly_names
#       Reference to an array of a disorder assembly codes.
##
sub get_assembly_names
{
    my ($atom_list) = @_;

    my %seen_names;
    for my $atom (@{$atom_list}) {
        if ($atom->{'assembly'} ne '.' || $atom->{'group'} ne '.' ) {
            $seen_names{$atom->{'assembly'}} = 1;
        }
    }
    return [ keys %seen_names ];
}

##
# Generate names for N new assemblies.
#
# @param $seen_assemblies
#       Reference to an array of already seen assembly names.
# @param $count
#       Number of new assemblies. Default: 1.
# @return @generated_names
#       Array of generated assembly names.
##
sub generate_additional_assembly_names
{
    my( $seen_assemblies, $count ) = @_;
    $count = 1 unless defined $count;

    my @seen_assemblies = sort { length $a <=> length $b || $a cmp $b }
                               @$seen_assemblies;

    # If the resulting data block is to have only a single assembly,
    # dot assembly is returned by default:
    return '.' if !@seen_assemblies && $count == 1;

    my $last_assembly = $seen_assemblies[-1];
    my @generated_names;

    # Make the first name
    if( !@seen_assemblies || $last_assembly eq '.' ) {
        # If none seen, start from 'A'
        push @generated_names, 'A';
    } else {
        $last_assembly =~ s/([a-z0-9]*)$//i;
        my $last_part = $1;
        if( $last_part eq '' ) {
            $last_part = 0;
        } else {
            # Perl supports '++' operator conveniently
            $last_part++;
        }
        push @generated_names, $last_assembly . $last_part;
    }

    for (2..$count) {
        my $last_assembly = $generated_names[-1];
        $last_assembly =~ s/([a-z0-9]*)$//i;
        my $last_part = $1;
        $last_part++;
        push @generated_names, $last_assembly . $last_part;
    }

    return @generated_names;
}

sub atom_is_disordered_strict
{
    my( $atom ) = @_;
    return 0 + any { exists $atom->{$_} && $atom->{$_} ne '.' }
                   ( 'assembly', 'group' );
}

sub atom_is_from_AU
{
    my( $atom ) = @_;
    return $atom->{'name'} eq $atom->{'site_label'};
}

1;
