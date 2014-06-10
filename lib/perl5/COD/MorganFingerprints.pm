#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  Compute Morgan fingerprints from atom connectivity list.
#**

package MorganFingerprints;

use strict;
use warnings;

no warnings 'recursion';

sub make_morgan_fingerprint
{
    my( $neighbours ) = @_;

    my $nr = scalar @{ $neighbours->{atoms} };
    return "" if $nr == 0;

    if( scalar @{ $neighbours->{neighbours} } == 0 ) {
        return $neighbours->{atoms}[0]{chemical_type}
    }

    my @orders;
    # Populate the initial list of node (atom) orders
    for( my $i = 0; $i < $nr; $i++ ) {
        $orders[$i] = scalar @{ $neighbours->{neighbours}[$i] };
    }

    # Update the list of atom connectivity values (according to
    # H. L. Morgan, The Generation of a Unique Machine Description for
    # Chemical Structures-A Technique Developed at Chemical Abstracts
    # Service, 1965) until the number of values stops to increase
    my %unique_orders = map { $_ => 1 } @orders;
    my $nr_unique_orders = scalar keys %unique_orders;
    while( 1 ) {
        my @orders_now;
        for( my $i = 0; $i < $nr; $i++ ) {
            my @neighbour_indices = @{ $neighbours->{neighbours}[$i] };
            $orders_now[$i] = sum( map { $orders[$_] }
                                       @neighbour_indices );
        }
        my %unique_orders_now = map { $_ => 1 } @orders_now;
        my $nr_unique_orders_now = scalar keys %unique_orders_now;
        if( $nr_unique_orders_now <= $nr_unique_orders ) {
            last;
        } else {
            @orders = @orders_now;
            $nr_unique_orders = $nr_unique_orders_now;
        }
    }

    # Order atoms according to the connectivity values
    my @sorted_order = sort { $orders[$b] <=> $orders[$a] ||
                              $neighbours->{atoms}[$a]{chemical_type} cmp
                              $neighbours->{atoms}[$b]{chemical_type} }
                       0..$#orders;
    my @atom_order;
    for( my $i = 0; $i < $nr; $i++ ) {
        $atom_order[$sorted_order[$i]] = $i;
    }

    # Traverse the graph starting from the atom with the largest
    # connectivity value, visiting each of it's unvisited children, sorted
    # by their connectivity values
    my $fingerprint = traverse_graph( $sorted_order[0],
                                      $neighbours,
                                      \@atom_order,
                                      \@orders,
                                      {} );
    return $fingerprint;
}

sub traverse_graph
{
    my( $atom, $neighbours, $atom_order, $orders, $seen_atoms ) = @_;

    $seen_atoms->{$atom} = 1;

    my @neighbours = @{ $neighbours->{neighbours}[$atom] };
    my @fingerprints;
    my @sorted_neighbours = sort { $atom_order->[$a] <=>
                                   $atom_order->[$b] } @neighbours;
    my @equivalent_neighbours;
    while( @sorted_neighbours > 0 ) {
        # Select a subset of atom's neighbours, that have same orders and
        # are of same chemical type
        my $atom2 = $sorted_neighbours[0];
        my $search_order = $orders->[$atom2];
        my $search_type  = $neighbours->{atoms}[$atom2]{chemical_type};
        my @equivalent_neighbours =
            grep { $orders->[$_] == $search_order &&
                   $neighbours->{atoms}[$_]{chemical_type} eq $search_type }
            @sorted_neighbours;
        @sorted_neighbours =
            grep { $orders->[$_] != $search_order ||
                   $neighbours->{atoms}[$_]{chemical_type} ne $search_type }
            @sorted_neighbours;

        # Remove already visited atoms from the subset
        my @equivalent_neighbours_now;
        foreach( @equivalent_neighbours ) {
            next if exists $seen_atoms->{$_};
            push( @equivalent_neighbours_now, $_ );
        }

        next if @equivalent_neighbours_now == 0;

        my @fingerprints_by_atoms;
        if( @equivalent_neighbours_now == 1 ) {
            @fingerprints_by_atoms =
                ( { atom => $equivalent_neighbours_now[0] } );
        } else {
            # Generate fingerprints for each member of subset
            # independently (giving identical sets of seen atoms)
            foreach (@equivalent_neighbours_now) {
                my %seen_atoms = %$seen_atoms;
                my $fingerprint = traverse_graph( $_,
                                                  $neighbours,
                                                  $atom_order,
                                                  $orders,
                                                  \%seen_atoms );
                push( @fingerprints_by_atoms,
                      { atom => $_,
                        fingerprint => $fingerprint } );
            }

            # Sort atoms in subset by their fingerprints
            @fingerprints_by_atoms =
                sort { $a->{fingerprint} cmp $b->{fingerprint} }
                @fingerprints_by_atoms;
        }

        # Generate the fingerprints one more time as the correct order
        # is determined and there should not be any randomness now
        foreach (@fingerprints_by_atoms) {
            my $atom = $_->{atom};
            next if exists $seen_atoms->{$atom};
            my $fingerprint = traverse_graph( $atom,
                                              $neighbours,
                                              $atom_order,
                                              $orders,
                                              $seen_atoms );
            push( @fingerprints, $fingerprint );
        }

        @equivalent_neighbours = ();
    }

    my $fingerprint = $neighbours->{atoms}[$atom]{chemical_type} .
                      "[" . $orders->[$atom] . "]";
    if( @fingerprints > 0 ) {
        $fingerprint .= "(" . join( "", @fingerprints ) . ")";
    }

    return $fingerprint;
}

sub traverse_graph_old
{
    my( $atom, $neighbours, $atom_order, $orders, $seen_atoms ) = @_;

    $seen_atoms->{$atom} = 1;

    my @neighbours = @{ $neighbours->{neighbours}[$atom] };
    my @fingerprints;
    foreach( sort { $atom_order->[$a] <=> $atom_order->[$b] } @neighbours ) {
        next if exists $seen_atoms->{$_};
        my $fingerprint = traverse_graph( $_,
                                          $neighbours,
                                          $atom_order,
                                          $orders,
                                          $seen_atoms );
        push( @fingerprints, $fingerprint );
    }

    my $fingerprint = $neighbours->{atoms}[$atom]{chemical_type} .
                      "[" . $orders->[$atom] . "]";
    if( @fingerprints > 0 ) {
        $fingerprint .= "(" . join( "", @fingerprints ) . ")";
    }

    return $fingerprint;
}

sub sum
{
    my $sum = 0.0;
    foreach( @_ ) { $sum += $_; }
    return $sum;
}

1;
