#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Build a list of neighbours for each atom from an atom list.
#**

package AtomNeighbours;

use strict;
use warnings;
use Carp;
use AtomBricks;

#==============================================================================
# Calculate Euclidean distance between two points given as Cartesian
# (orthogonal) coordinates.

sub distance($$)
{
    my ($xyz1, $xyz2) = @_;

    return sqrt(
        ($xyz1->[0] - $xyz2->[0]) ** 2 +
        ($xyz1->[1] - $xyz2->[1]) ** 2 +
        ($xyz1->[2] - $xyz2->[2]) ** 2
    );
}

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
#       covalent radii; can be obtained e.e. from the AtomProperties module.
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
        AtomBricks::build_bricks( $neighbour_list{atoms},
                                  $max_covalent_radius * 2 +
                                  $extra_bond_distance );

    do {
        use Serialise;
        serialiseRef( $bricks );
    } if 0;

    $atom_list = $neighbour_list{atoms};

    for my $i (0..$#{$atom_list}) {
        my @coordinates = @{$atom_list->[$i]{coordinates_ortho}};

        my ($ai, $aj, $ak) =
            AtomBricks::get_atom_index( $bricks, @coordinates );

        my ( $min_i, $max_i, $min_j, $max_j, $min_k, $max_k );
        ( $min_i, $max_i, $min_j, $max_j, $min_k, $max_k ) =
            AtomBricks::get_search_span( $bricks, $ai, $aj, $ak );

        my $atom1 = $atom_list->[$i];

        for $ai ($min_i .. $max_i) {
        for $aj ($min_j .. $max_j) {
        for $ak ($min_k .. $max_k) {
            ## for my $j (0..$#{$atom_list}) {
            for my $atom2 ( @{$bricks->{atoms}[$ai][$aj][$ak]} ) {

                next if $atom1 == $atom2;

                next if exists $atom1->{atom_assembly} &&
                        exists $atom2->{atom_assembly} &&
                        $atom1->{atom_assembly} ne '.' &&
                        $atom2->{atom_assembly} ne '.' &&
                        $atom1->{atom_assembly} eq $atom2->{atom_assembly} &&
                        exists $atom1->{atom_group} &&
                        exists $atom2->{atom_group} &&
                        $atom1->{atom_group} ne '.' &&
                        $atom2->{atom_group} ne '.' &&
                        $atom1->{atom_group} ne $atom2->{atom_group};

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

1;
