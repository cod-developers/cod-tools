#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Build a list of neighbours for each atom from an atom list.
#**

package COD::AtomNeighbours;

use strict;
use warnings;
use Carp qw( croak );
use COD::AtomBricks qw( build_bricks get_atom_index get_search_span );
use COD::AtomProperties;
use COD::Algebra::Vector qw( distance );
use COD::CIF::Data::AtomList qw( atom_array_from_cif
                                 atoms_are_alternative
                                 datablock_from_atom_array );
use COD::CIF::Tags::Manage qw( has_special_value
                               set_loop_tag
                               tag_is_empty );

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    get_max_covalent_radius
    get_max_vdw_radius
    make_neighbour_list
    neighbour_list_from_chemistry_mol
    neighbour_list_from_chemistry_opensmiles
    neighbour_list_from_cif
    neighbour_list_to_cif_datablock
    neighbour_list_to_graph
);

#==============================================================================#
# Find a maximal covalent radius in the atom property list.
#
# @arg: $atom_properties should be a hash of the form described in
#       AtomProperties.pm module.

sub get_max_covalent_radius($)
{
    my ($atom_properties) = @_;

    my $max_radius = 0;

    for my $atom (keys %$atom_properties) {
        if( $max_radius < $atom_properties->{$atom}{covalent_radius} ) {
            $max_radius = $atom_properties->{$atom}{covalent_radius};
        }
    }

    return $max_radius;
}

#==============================================================================#
# Find a maximal van der Waals radius in the atom property list.
#
# @arg: $atom_properties should be a hash of the form described in
#       AtomProperties.pm module.

sub get_max_vdw_radius($)
{
    my ($atom_properties) = @_;

    my $max_radius = 0;

    for my $atom (keys %$atom_properties) {
        if( $max_radius < $atom_properties->{$atom}{vdw_radius} ) {
            $max_radius = $atom_properties->{$atom}{vdw_radius};
        }
    }

    return $max_radius;
}

#==============================================================================
# sub make_neighbour_list
#
# Creates and returns atom neighbour list from an atom list (as
# returned by the make_atom_list function from the CIFAtomList.pm
# module).
#
# @arg: $atom_list -- an atom_list returned by the make_atom_list() function
#
# @arg: $extra_bond_distance -- extra distance to be added to
#       a sum of atom covalent radii when checking for a covalent bond.
#
# @arg: $bump_distance_factor -- A fraction of covalent radii sum used
#       to determine when atoms are too close and are considered a
#       bump.
#
# @arg: $atom_property_list -- a hash with atom properties, containing
#       covalent radii; can be obtained i.e. from the AtomProperties module.
#
# @ret: an array or a reference to an array with a neighbour list
#       for each atom:
#
# @returned = (
#   atoms => [ $a1, $a2, $a3, $a4, $a5, $a6 ],
#   neighbours => [
#       #   0: neighbours for atom $a1 (atom index 0):
#       [ 0, 3, 4 ],
#       # next atom with its neighbours, and so on ...
#   ],
# )

sub make_neighbour_list($$$$@)
{
    my ($atom_list, $extra_bond_distance, $bump_distance_factor,
        $atom_properties, $ignore_bumps) = @_;

    my $max_covalent_radius =
        get_max_covalent_radius( $atom_properties );

    $ignore_bumps = 0 unless defined $ignore_bumps;

    my $n = 0;
    my %neighbour_list = (
        atoms => [ map { {%$_, index => $n++} } @$atom_list ],
        neighbours => [],
    );

    my $bricks =
        build_bricks( $neighbour_list{atoms},
                                  $max_covalent_radius * 2 +
                                  $extra_bond_distance );

    do {
        use COD::Serialise qw( serialiseRef );
        serialiseRef( $bricks );
    } if 0;

    $atom_list = $neighbour_list{atoms};

    for my $i (0..$#{$atom_list}) {
        my @coordinates = @{$atom_list->[$i]{coordinates_ortho}};

        my ($ai_init, $aj_init, $ak_init) =
            get_atom_index( $bricks, @coordinates );

        my ( $min_i, $max_i, $min_j, $max_j, $min_k, $max_k );
        ( $min_i, $max_i, $min_j, $max_j, $min_k, $max_k ) =
            get_search_span( $bricks, $ai_init, $aj_init, $ak_init );

        my $atom1 = $atom_list->[$i];

        for my $ai ($min_i .. $max_i) {
        for my $aj ($min_j .. $max_j) {
        for my $ak ($min_k .. $max_k) {
            ## for my $j (0..$#{$atom_list}) {
            for my $atom2 ( @{$bricks->{atoms}[$ai][$aj][$ak]} ) {

                next if $atom1 == $atom2;
                next if atoms_are_alternative( $atom1, $atom2 );

                my $atom1_type =  $atom1->{chemical_type};
                my $atom2_type =  $atom2->{chemical_type};

                my $max_bond_distance =
                    max_bond_distance( $atom1_type, $atom2_type,
                                       $extra_bond_distance,
                                       $atom_properties );

                my $nominal_bond_distance =
                    max_bond_distance( $atom1_type, $atom2_type,
                                       0, $atom_properties );

                my $bond_distance =
                    distance( $atom1->{coordinates_ortho},
                              $atom2->{coordinates_ortho} );

                next if $bond_distance >= $max_bond_distance;

                if( $bond_distance <
                    $bump_distance_factor * $nominal_bond_distance ) {
                    if( !$ignore_bumps ) {
                        croak( "atoms \"$atom_list->[$i]{name}\" and " .
                               "\"$atom2->{name}\" are too close " .
                               "(distance = " .
                               sprintf( "%6.4f", $bond_distance ) .
                               "), and are considered a bump " .
                               "-- aborting calculations" );
                        next;
                    } else {
                        $atom1->{is_bump} = 1;
                        $atom2->{is_bump} = 1;
                    }
                }

                push( @{$neighbour_list{neighbours}[$i]},
                      $atom2->{index} );
            }
        }}}
    }

    for my $nlist (@{$neighbour_list{neighbours}}) {
        if( defined $nlist ) {
            @$nlist = sort { $a <=> $b } @$nlist;
        }
    }

    return wantarray ? %neighbour_list : \%neighbour_list;
}

#==============================================================================
# Return a maximum expected covalent bond distance for atoms of given
# type, after consulting an atom property table. Atom types are guven
# by symbols used in the Mendeleyev's periodic table; they are used as
# keys in the $atom_properties-referenced hash.

sub max_bond_distance($$$$)
{
    my ($atom1_type, $atom2_type, $extra_distance, $atom_properties ) = @_;

    if( ! exists $atom_properties->{$atom1_type} ) {
        croak( "unknown atom type '$atom1_type'" );
    }
    if( ! exists $atom_properties->{$atom2_type} ) {
        croak( "unknown atom type '$atom2_type'" );
    }

    my $atom1_covalent_radius =
        $atom_properties->{$atom1_type}{covalent_radius};

    my $atom2_covalent_radius =
        $atom_properties->{$atom2_type}{covalent_radius};

    return $atom1_covalent_radius + $atom2_covalent_radius + $extra_distance;
}

#==============================================================================
# sub make_atom_neighbour_list_slow
#
# Old algorithm that does not use AtomBricks.pm to speed up searches;
# its run time grows as a square of atom number, and it is not
# recommended for real calculations, but is retained for debugging
# purposes.

sub make_neighbour_list_slow($$$$$)
{
    my ($atom_list, $extra_bond_distance, $bump_distance_factor,
        $atom_properties, $ignore_bumps) = @_;

    my $n = 0;
    my %neighbour_list = (
        atoms => [ map { {%$_, index => $n++} } @$atom_list ],
        neighbours => [],
    );

    $atom_list = $neighbour_list{atoms};

    for my $i (0..$#{$atom_list}) {
        for my $j (0..$#{$atom_list}) {
            next if $i == $j;

            my $atom1_type =  $atom_list->[$i]{chemical_type};
            my $atom2_type =  $atom_list->[$j]{chemical_type};

            my $max_bond_distance =
                max_bond_distance( $atom1_type, $atom2_type,
                                   $extra_bond_distance,
                                   $atom_properties );

            my $nominal_bond_distance =
                max_bond_distance( $atom1_type, $atom2_type,
                                   0, $atom_properties );
            my $bond_distance =
                distance( $atom_list->[$i]{coordinates_ortho},
                          $atom_list->[$j]{coordinates_ortho} );

            if( $bond_distance <
                $bump_distance_factor * $nominal_bond_distance &&
                !$ignore_bumps ) {
                croak( "atoms \"$atom_list->[$i]{name}\" and " .
                       "\"$atom_list->[$j]{name}\" are too close " .
                       "(distance = " .
                       sprintf( "%6.4f", $bond_distance ) .
                       "), and are considered a bump" );
            } elsif( $bond_distance < $max_bond_distance ) {
                push( @{$neighbour_list{neighbours}[$i]}, $j );
            }
        }
    }

    return wantarray ? %neighbour_list : \%neighbour_list;
}

#==============================================================================
# Generates neighbour list from Chemistry::Mol object. Tested with the
# version 0.37 of the aforementioned module.
#
# Deprecated as Chemistry::Mol fails on newer Perl versions.
sub neighbour_list_from_chemistry_mol
{
    my( $mol ) = @_;

    my %neighbour_list = (
        atoms => [],
        neighbours => [],
    );

    my %atom_ids;
    my $n = 0;
    for my $atom ($mol->atoms()) {
        my %atom_info;

        $atom_info{"name"}                  = $atom->symbol() . ($n+1);
        $atom_info{"site_label"}            = $atom->symbol() . ($n+1);
        $atom_info{"cell_label"}            = $atom->symbol() . ($n+1);
        $atom_info{"index"}                 = $n;
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

        $atom_info{"chemical_type"}         = $atom->symbol();
        $atom_info{"assembly"}              = ".";
        $atom_info{"group"}                 = ".";
        $atom_info{"atom_site_occupancy"}   = 1;
        $atom_info{"attached_hydrogens"}    = $atom->implicit_hydrogens();

        # Aromatic atoms are considered planar only if they have three
        # or more neighbours, as any three points lie on the same
        # plane.
        if( defined $atom->attr('smiles/aromatic') &&
            $atom->attr('smiles/aromatic') == 1 &&
            (scalar $atom->neighbors() +
             $atom_info{"attached_hydrogens"}) >= 3 ) {
            $atom_info{"planarity"} = 0;
        }

        $atom_ids{$atom} = $n;
        push @{$neighbour_list{atoms}}, \%atom_info;

        $n ++;
    }

    for my $atom ($mol->atoms()) {
        push @{$neighbour_list{neighbours}},
             [ map { $atom_ids{$_} } $atom->neighbors() ];
    }

    return \%neighbour_list;
}

#==============================================================================
# Generates neighbour list from Chemistry::OpenSMILES graphs-moieties.
sub neighbour_list_from_chemistry_opensmiles
{
    my( $moiety ) = @_;

    my $neighbour_list = {
        atoms      => [],
        neighbours => [],
    };

    my %indexes;
    for my $atom (sort { $a->{number} <=> $b->{number} } $moiety->vertices) {
        my %atom_info = (
            name       => ucfirst( $atom->{symbol} ) . ($atom->{number} + 1),
            site_label => ucfirst( $atom->{symbol} ) . ($atom->{number} + 1),
            cell_label => ucfirst( $atom->{symbol} ) . ($atom->{number} + 1),
            index      => $atom->{number},
            symop      =>
                [
                    [ 1, 0, 0, 0 ],
                    [ 0, 1, 0, 0 ],
                    [ 0, 0, 1, 0 ],
                    [ 0, 0, 0, 1 ],
                ],
            symop_id             => 1,
            unity_matrix_applied => 1,
            translation_id       => '555',
            translation          => [ 0, 0, 0 ],
            chemical_type        => ucfirst( $atom->{symbol} ),
            assembly             => '.',
            group                => '.',
            atom_site_occupancy  => 1,
            attached_hydrogens   => $atom->{hcount},
        );

        # Aromatic atoms are considered planar only if they have three
        # or more neighbours, as any three points lie on the same
        # plane.
        if( ucfirst( $atom->{symbol} ) ne $atom->{symbol} &&
            $moiety->degree( $atom ) +
            (exists $atom->{hcount} ? $atom->{hcount} : 0) >= 3 ) {
            $atom_info{planarity} = 0;
        }

        $indexes{$atom} = $atom->{number};
        push @{$neighbour_list->{atoms}}, \%atom_info;
    }

    for my $bond ($moiety->edges) {
        push @{$neighbour_list->{neighbours}[$indexes{$bond->[0]}]},
             $indexes{$bond->[1]};
        push @{$neighbour_list->{neighbours}[$indexes{$bond->[1]}]},
             $indexes{$bond->[0]};
    }

    for my $list (@{$neighbour_list->{neighbours}}) {
        @$list = sort @$list;
    }

    return $neighbour_list;
}

#==============================================================================
# Reads neighbour list from CIF datablock.
sub neighbour_list_from_cif
{
    my( $datablock, $options ) = @_;

    my $neighbour_list = {
        atoms => atom_array_from_cif( $datablock, $options ),
        neighbours => [],
    };

    if( tag_is_empty( $datablock, '_geom_bond_atom_site_label_1' ) ||
        tag_is_empty( $datablock, '_geom_bond_atom_site_label_2' ) ) {
        # TODO: emit warning maybe
        return $neighbour_list;
    }

    my %indexes = map { $_->{name} => $_->{index} } @{$neighbour_list->{atoms}};

    my $values = $datablock->{values};
    for my $i (0..$#{$values->{_geom_bond_atom_site_label_1}}) {
        if( has_special_value( $datablock, '_geom_bond_atom_site_label_1', $i ) ||
            has_special_value( $datablock, '_geom_bond_atom_site_label_2', $i ) ) {
            warn "$i-th packet of '_geom_bond_atom_site_label_*' loop " .
                 "has special CIF value(s), skipping\n";
            next;
        }

        my $label1 = $values->{_geom_bond_atom_site_label_1}[$i];
        my $label2 = $values->{_geom_bond_atom_site_label_2}[$i];

        if( !exists $indexes{$label1} ) {
            warn "atom with label '$label1' is not found, skipping\n";
            next;
        }
        if( !exists $indexes{$label2} ) {
            warn "atom with label '$label2' is not found, skipping\n";
            next;
        }

        my $index1 = $indexes{$label1};
        my $index2 = $indexes{$label2};

        push @{$neighbour_list->{neighbours}[$index1]}, $index2;
        push @{$neighbour_list->{neighbours}[$index2]}, $index1;
    }

    for my $i (0..$#{$neighbour_list->{neighbours}}) {
        next if !$neighbour_list->{neighbours}[$i];
        $neighbour_list->{neighbours}[$i] =
            [ sort { $a <=> $b } @{$neighbour_list->{neighbours}[$i]} ];
    }

    return $neighbour_list;
}

#==============================================================================
# Generates CIF datablock from neighbour list. Bonds are represented in
# _geom_bond_* CIF data items.
sub neighbour_list_to_cif_datablock
{
    my( $neighbour_list ) = @_;

    my $datablock = datablock_from_atom_array( $neighbour_list->{atoms} );
    my @labels1 = map { $neighbour_list->{atoms}[$_]{name} }
                  map { ( $_ ) x scalar @{$neighbour_list->{neighbours}[$_]} }
                      0..$#{$neighbour_list->{neighbours}};
    my @labels2 = map { $neighbour_list->{atoms}[$_]{name} }
                  map { @{$neighbour_list->{neighbours}[$_]} }
                      0..$#{$neighbour_list->{neighbours}};

    set_loop_tag( $datablock,
                  '_geom_bond_atom_site_label_1',
                  '_geom_bond_atom_site_label_1',
                  [ map  { $labels1[$_] }
                    grep { $labels1[$_] le $labels2[$_] }
                         0..$#labels1 ] );
    set_loop_tag( $datablock,
                  '_geom_bond_atom_site_label_2',
                  '_geom_bond_atom_site_label_1',
                  [ map  { $labels2[$_] }
                    grep { $labels1[$_] le $labels2[$_] }
                         0..$#labels2 ] );
    return $datablock;
}

#==============================================================================
# Generates Graph::Undirected object from neighbour list
sub neighbour_list_to_graph
{
    my( $neighbour_list ) = @_;

    require Graph::Undirected;

    my $graph = Graph::Undirected->new;
    for my $atom (@{$neighbour_list->{atoms}}) {
        $graph->add_vertex( $atom );
        my $index1 = $atom->{index};
        for my $index2 (@{$neighbour_list->{neighbours}[$index1]}) {
            next if $index1 > $index2;
            next if !defined $neighbour_list->{atoms}[$index2];
            $graph->add_edge( $neighbour_list->{atoms}[$index1],
                              $neighbour_list->{atoms}[$index2] );
        }
    }

    return $graph;
}

1;
