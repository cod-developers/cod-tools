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

sub make_morgan_fingerprint
{
    my( $neighbours, $use_atom_classes, $classification_level,
        $max_ring_size, $flat_planarity ) = @_;

    my $nr = scalar @{ $neighbours->{atoms} };
    return "" if $nr == 0;

    if( scalar @{ $neighbours->{neighbours} } == 0 ) {
        return $neighbours->{atoms}[0]{chemical_type}
    }

    if( $use_atom_classes ) {
        require AtomClassifier;

        my $neighbours_old = [];
        for( my $i = 0; $i < $nr; $i++ ) {
            my %atom = %{ $neighbours->{atoms}[$i] };
            $atom{index} = $i;
            $atom{atom_name} = $atom{name};
            $atom{atom_type} = $atom{chemical_type};
            push( @$neighbours_old, [ \%atom ] );
        }

        for( my $i = 0; $i < $nr; $i++ ) {
            $neighbours_old->[$i][1] =
                [ map { $neighbours_old->[$_][0] }
                      @{$neighbours->{neighbours}[$i]} ];
        }

        AtomClassifier::assign_atom_planarities( $neighbours_old,
                                                 $flat_planarity );
        AtomClassifier::classify_atoms( $neighbours_old,
                                        $classification_level,
                                        $max_ring_size,
                                        $flat_planarity );

        for( my $i = 0; $i < $nr; $i++ ) {
            $neighbours->{atoms}[$i]{atom_class} =
                $neighbours_old->[$i][0]{atom_class};
        }
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
    my @sorted_order;
    if( $use_atom_classes ) {
        @sorted_order = sort { $orders[$b] <=> $orders[$a] ||
                               $neighbours->{atoms}[$a]{atom_class} cmp
                               $neighbours->{atoms}[$b]{atom_class} }
                             0..$#orders;
    } else {
        @sorted_order = sort { $orders[$b] <=> $orders[$a] ||
                               $neighbours->{atoms}[$a]{chemical_type} cmp
                               $neighbours->{atoms}[$b]{chemical_type} }
                             0..$#orders;
    }

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
                                      {},
                                      $use_atom_classes );
    return $fingerprint;
}

sub traverse_graph
{
    my( $atom, $neighbours, $atom_order, $orders, $seen_atoms,
        $use_atom_classes ) = @_;

    $seen_atoms->{$atom} = 1;

    my @neighbours = @{ $neighbours->{neighbours}[$atom] };
    my @fingerprints;
    foreach( sort { $atom_order->[$a] <=> $atom_order->[$b] } @neighbours ) {
        next if exists $seen_atoms->{$_};
        my $fingerprint = traverse_graph( $_,
                                          $neighbours,
                                          $atom_order,
                                          $orders,
                                          $seen_atoms,
                                          $use_atom_classes );
        push( @fingerprints, $fingerprint );
    }

    my $atom_identifyer =
        $use_atom_classes ? 'atom_class' : 'chemical_type';

    my $fingerprint = $neighbours->{atoms}[$atom]{$atom_identifyer} .
                      "{" . $orders->[$atom] . "}";
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
