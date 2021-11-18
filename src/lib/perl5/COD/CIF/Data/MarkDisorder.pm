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
use COD::CIF::Data qw( get_cell );
use COD::CIF::Data::AtomList qw( atom_array_from_cif );
use COD::CIF::Tags::Manage qw( set_tag set_loop_tag );
use COD::Fractional qw( symop_ortho_from_fract );
use COD::Spacegroups::Symop::Algebra qw( symop_vector_mul );
use COD::Algebra::Vector qw( distance );
use List::Util qw( sum );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    mark_disorder
);

#==============================================================================#
# Find alternatives among CIF atoms
# Accepts
#    atom_list - CIF atom list, as returned by initial_atoms()
#    bricks    - CIF atom bricks, as returned by build_bricks()
# Returns
#    $alternatives = {
#       $atom_number => [ $assembly, $group ]
#    }
sub get_alternatives
{
    my( $atom_list, $bricks, $f2o, $options ) = @_;

    $options = {} unless $options;
    my $default_options = {
        same_site_distance_sensitivity => 0.000001,
        same_site_occupancy_sensitivity => 0.01,
        exclude_zero_occupancies => 1,
        ignore_occupancies => 0,
    };
    for my $key (keys %$default_options) {
        next if exists $options->{$key};
        $options->{$key} = $default_options->{$key};
    }

    my @assemblies;
    my %in_assembly;

    for my $current_atom (@$atom_list) {
        # Skipping dummy atoms
        if( $current_atom->{coordinates_fract}[0] eq '.' ||
            $current_atom->{coordinates_fract}[1] eq '.' ||
            $current_atom->{coordinates_fract}[2] eq '.' ) {
            next;
        }

        my $atom_in_unit_cell_coords_ortho =
            symop_vector_mul( $f2o, $current_atom->{coordinates_fract} );

        my ($i_init, $j_init, $k_init) =
            get_atom_index( $bricks, @{$atom_in_unit_cell_coords_ortho});

        my( $min_i, $max_i, $min_j, $max_j, $min_k, $max_k ) =
            get_search_span( $bricks, $i_init, $j_init, $k_init );

        my $name1 = $current_atom->{name};
        my $index1 = $current_atom->{index};

        for my $i ($min_i .. $max_i) {
        for my $j ($min_j .. $max_j) {
        for my $k ($min_k .. $max_k) {
            for my $atom ( @{$bricks->{atoms}[$i][$j][$k]} ) {
                my $atom_coords_ortho = $atom->{coordinates_ortho};
                my $name2 = $atom->{name};
                my $index2 = $atom->{index};

                next if $index1 ge $index2;
                next if !exists $atom->{atom_site_occupancy} ||
                       ($atom->{atom_site_occupancy} eq '0.0' &&
                        $options->{exclude_zero_occupancies}) ||
                        $atom->{atom_site_occupancy} eq '?' ||
                        $atom->{atom_site_occupancy} eq '.';

                my $dist = distance( $atom_in_unit_cell_coords_ortho,
                                     $atom_coords_ortho );
                next if $dist > $options->{same_site_distance_sensitivity};

                # Skipping initially marked disordered atoms:
                if( exists $current_atom->{assembly} &&
                    exists $atom->{assembly} &&
                    $current_atom->{assembly} eq $atom->{assembly} &&
                    exists $current_atom->{group} &&
                    exists $atom->{group} &&
                    $current_atom->{group} ne $atom->{group} ) {
                    next;
                }

                if( !exists $in_assembly{$index1} &&
                    !exists $in_assembly{$index2} ) {
                    # Creating new assembly
                    $in_assembly{$index1} = scalar @assemblies;
                    $in_assembly{$index2} = scalar @assemblies;
                    push( @assemblies, [ $index1, $index2 ] );
                } elsif( exists $in_assembly{$index1} &&
                         exists $in_assembly{$index2} ) {
                    my $assembly1 = $in_assembly{$index1};
                    my $assembly2 = $in_assembly{$index2};
                    next if $assembly1 == $assembly2;

                    # Merging two assemblies
                    my @new_assembly = ( @{$assemblies[$assembly1]},
                                         @{$assemblies[$assembly2]} );
                    foreach( @{$assemblies[$assembly1]},
                             @{$assemblies[$assembly2]} ) {
                        $in_assembly{$_} = scalar @assemblies;
                    }
                    $assemblies[$assembly1] = [];
                    $assemblies[$assembly2] = [];
                    push @assemblies, \@new_assembly;
                } else {
                    # Joining one atom to the assembly
                    if( exists $in_assembly{$index1} ) {
                        push @{$assemblies[$in_assembly{$index1}]},
                             $index2;
                        $in_assembly{$index2} = $in_assembly{$index1};
                    } else {
                        push @{$assemblies[$in_assembly{$index2}]},
                             $index1;
                        $in_assembly{$index1} = $in_assembly{$index2};
                    }
                }
            }
        }}}
    }

    my $count = 0;
    my %assemblies_now;

    for my $assembly (@assemblies) {
        next if @$assembly == 0;
        my $occupancy_sum =
            sum( 0.0, map { /(.*?)(?:[(][0-9]+[)])?$/; $1 }
                      map { $atom_list->[$_]{atom_site_occupancy} }
                      @$assembly );
        if( abs( $occupancy_sum - 1 ) >
            $options->{same_site_occupancy_sensitivity} &&
            !$options->{ignore_occupancies} ) {
            my @names = sort map { $atom_list->[$_]{name} } @$assembly;
            warn "WARNING, atoms " . join( ", ", map { "'$_'" } @names )
               . " share the same site, but the sum of their "
               . "occupancies is $occupancy_sum\n";
            next;
        }
        my $group_nr = 1;
        foreach( sort @$assembly ) {
            $assemblies_now{$_} = [ $count, $group_nr ];
            $group_nr++;
        }
        $count++;
    }

    return \%assemblies_now;
}

#==============================================================================#
# Indicates whether supplied atom list contains dot assembly.
sub has_dot_assembly
{
    my( $atom_list ) = @_;
    my %assemblies = map  { $_->{assembly} => 1 }
                     grep { $_->{assembly} ne '.' ||
                            $_->{group} ne '.' }
                     @$atom_list;
    return exists $assemblies{'.'};
}

#==============================================================================#
# Find and mark disorder in a given CIF data block (overwrites old values)
# Accepts
#    dataset         - CIF data block, as produced by COD::CIF::Parser
#    atom_properties - atom properties structure, as from COD::AtomProperties
#    options         - various options to control the algorithm
sub mark_disorder
{
    my( $dataset, $atom_properties, $options ) = @_;
    my $values = $dataset->{values};

    $options = {} unless $options;
    my $default_options = {
        same_site_distance_sensitivity => 0.000001,
        same_site_occupancy_sensitivity => 0.01,
        brick_size => 1,
        exclude_zero_occupancies => 1,
        report_marked_disorders => 1,
        ignore_occupancies => 0,
        messages_to_depositor_comments => 1,
    };
    for my $key (keys %$default_options) {
        next if exists $options->{$key};
        $options->{$key} = $default_options->{$key};
    }

    # Extract atoms fract coordinates
    my $atom_list =
        atom_array_from_cif( $dataset,
                             { allow_unknown_chemical_types => 1,
                               exclude_unknown_coordinates => 1,
                               exclude_dummy_coordinates => 1,
                               assume_full_occupancy => 1,
                               atom_properties => $atom_properties } );

    my %assemblies = map  { $_->{assembly} => 1 }
                     grep { $_->{assembly} ne '.' ||
                            $_->{group} ne '.' }
                     @$atom_list;
    my @all_assemblies = sort {($a =~ /^[0-9]+$/ && $b =~ /^[0-9]+$/)
                                    ? $a <=> $b
                                    : $a cmp $b} keys %assemblies;
    my $assembly_count = scalar @all_assemblies;

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

    my @new_assemblies;
    for my $atom_index (keys %$alternatives) {
        my $assembly_nr = $alternatives->{$atom_index}[0];
        if( !defined $new_assemblies[$assembly_nr] ) {
            $new_assemblies[$assembly_nr] = [];
        }
        push @{$new_assemblies[$assembly_nr]}, $atom_index;
    }

    my $rename_dot_assembly_to;
    if( has_dot_assembly( $atom_list ) &&
        ($assembly_count > 1 || scalar( keys %$alternatives ) > 0) ) {
        if( $all_assemblies[-1] eq '.' ) {
            $rename_dot_assembly_to = 'A';
        } elsif( grep { !/^[A-Y]$/ } @all_assemblies == 0 ) {
            $rename_dot_assembly_to =
                chr( ord( $all_assemblies[-1] ) + 1 );
        } else {
            my @numeric = grep { /^[0-9]+$/ } @all_assemblies;
            $rename_dot_assembly_to = $all_assemblies[-1] + 1;
        }
        rename_dot_assembly( $atom_list, $rename_dot_assembly_to );
        push @all_assemblies, $rename_dot_assembly_to;
        @all_assemblies = sort {($a =~ /^[0-9]+$/ && $b =~ /^[0-9]+$/)
                                    ? $a <=> $b
                                    : $a cmp $b}
                          @all_assemblies;
    }

    my @assembly_names;
    if( @all_assemblies == 0 &&
        ord( 'A' ) + @new_assemblies <= ord( 'Z' ) ) {
        @assembly_names = map { chr( ord( 'A' ) + $_ - 1 ) }
                              1..@new_assemblies;
    } elsif( @all_assemblies > 0 &&
             scalar( grep { !/^[A-Z\.]$/ } @all_assemblies ) == 0 &&
             ord( $all_assemblies[-1] ) + @new_assemblies <= ord( 'Z' ) ) {
        @assembly_names = map { chr( ord( $all_assemblies[-1] ) + $_ ) }
                              1..@new_assemblies;
    } else {
        my @numeric = grep { /^[0-9]+$/ } @all_assemblies;
        my $first = (@numeric > 0) ? $numeric[-1] : 0;
        @assembly_names = map { $first + $_ } 1..@new_assemblies;
    }

    # Creating arrays of assembly and groups symbols to be recorded in
    # CIF loops
    for my $atom (@$atom_list) {
        my $index = $atom->{index};
        if( exists $alternatives->{$index} ) {
            $atom->{assembly} = $assembly_names[$alternatives->{$index}[0]];
            $atom->{group} = $alternatives->{$index}[1];
        } elsif( !exists $atom->{assembly} ||
                 !exists $atom->{group} ||
                 $atom->{assembly} eq '.' ) {
            $atom->{assembly} = '.';
            $atom->{group} = '.';
        }
    }

    my @assemblies = map { $_->{assembly} } @$atom_list;
    my @groups = map { $_->{group} } @$atom_list;

    # Modifying the CIF data structure and issuing messages
    if( @new_assemblies > 0 || defined $rename_dot_assembly_to ) {

        my @messages;
        if( defined $rename_dot_assembly_to ) {
            my $msg = "disorder assembly '.' was renamed to " .
                      "'$rename_dot_assembly_to'";
            push( @messages, $msg );
            warn "NOTE, $msg\n";
        }

        for my $assembly (@new_assemblies) {
            my @names = sort map { $atom_list->[$_]{name} } @$assembly;
            my $msg = "atoms " . join( ', ', map { "'$_'" } @names ) .
                      " were marked as alternatives";
            push( @messages, $msg );
            if( $options->{report_marked_disorders} ) {
                warn "NOTE, $msg\n";
            }
        }

        if( @new_assemblies > 0 ) {
            warn "NOTE, ". scalar( @new_assemblies ) . " site(s) "
               . "were marked as disorder assemblies\n";
        }

        my $atom_site_tag;

        if( exists $values->{'_atom_site_label'} ) {
            $atom_site_tag = '_atom_site_label';
        } else {
            $atom_site_tag = '_atom_site_type_symbol';
        }

        set_loop_tag( $dataset,
                      '_atom_site_disorder_assembly',
                      $atom_site_tag,
                      \@assemblies );
        set_loop_tag( $dataset,
                      '_atom_site_disorder_group',
                      $atom_site_tag,
                      \@groups );

        if( $options->{messages_to_depositor_comments} ) {
            my $comment = "  The following automatic conversions " .
                          "were performed:\n\n";
            $comment .= join( "\n", map { '  ' . ucfirst($_) . '.' }
                                            @messages ) . "\n\n";
            $comment .= '  Automatic conversion script';
            if( defined $options->{depositor_comments_signature} ) {
                $comment .= "\n  " . $options->{depositor_comments_signature}
            }
            if( !$values->{_cod_depositor_comments} ) {
                set_tag( $dataset,
                         '_cod_depositor_comments',
                         "\n$comment" );
            } else {
                $values->{_cod_depositor_comments}[-1] .=
                    "\n\n$comment";
            }
        }
    }

    return;
}

#==============================================================================#
# Renames dot assembly with a given symbol.
sub rename_dot_assembly
{
    my( $atom_list, $new_assembly ) = @_;
    for my $atom (@$atom_list) {
        next if !exists $atom->{assembly};
        next if !exists $atom->{group};
        if( $atom->{assembly} eq '.' &&
            $atom->{group} ne '.' ) {
            $atom->{assembly} = $new_assembly;
        }
    }

    return;
}

1;
