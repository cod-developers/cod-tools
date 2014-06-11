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
