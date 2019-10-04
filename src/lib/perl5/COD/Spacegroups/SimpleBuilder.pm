#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*

# A Perl object to build all spacegroup operators and spacegroup
# description from symmetry operators supplied one by one or as a
# list.

# This module, the SimpleBuilder, implements the simplest but
# inefficient form of the algorthm; this algorithm follows directly
# from the definition of the group (all group elements, when
# multiplied with each other, must yield other group elements), and
# is mentioned in [1] as "fairly trivial". The intended use of this
# algorithm is to generated several test cases for more efficient
# ones.

# [1] Grosse-Kunstleve, R. W. Algorithms for deriving crystallographic
# space-group information. Acta crystallographica. Section A,
# Foundations of crystallography, 1999, 55,
# 383-395. URL: https://doi.org/10.1107/S0108767398010186

#**

package COD::Spacegroups::SimpleBuilder;

use strict;
use warnings;
use COD::Algebra::Vector qw( vector_sub vector_add vector_modulo_1
                             vector_is_zero vectors_are_equal round_vector );
use COD::Spacegroups::Symop::Parse qw( 
    symop_from_string string_from_symop symop_string_canonical_form
);
use COD::Spacegroups::Symop::Algebra qw(
    symop_mul symop_modulo_1 symop_translate symop_translation
    symop_set_translation symop_is_inversion symops_are_equal
    flush_zeros_in_symop symop_is_translation
);

my $debug = 0;

use fields qw(
    symops symop_hash
);

my $unity_symop = [
    [ 1, 0, 0, 0 ],
    [ 0, 1, 0, 0 ],
    [ 0, 0, 1, 0 ],
    [ 0, 0, 0, 1 ],
];

my $inversion_symop = [
    [-1, 0, 0, 0 ],
    [ 0,-1, 0, 0 ],
    [ 0, 0,-1, 0 ],
    [ 0, 0, 0, 1 ],
];

sub debug
{
    my ($debug_flag) = @_;
    $debug = ($debug_flag? 1:0);
}

sub new { 
    my ($self) = @_;

    $self = fields::new($self) unless (ref $self);
    $self->{symops} = [ $unity_symop ];
    my $symop_key = string_from_symop( $unity_symop );
    $self->{symop_hash}{$symop_key} = $unity_symop;
    return $self;
}

sub print
{
    my ($self, $fd) = @_;

    $fd = \*STDOUT unless defined $fd;
    
    print $fd "nsymops:   ", int(@{$self->all_symops()}), "\n";
    print $fd "symops:\n";
    for my $symop (@{$self->all_symops()}) {
        print $fd "    ", string_from_symop( $symop ), "\n"
    }
    print $fd "\n";
}

sub snap_number_to_crystallographic
{
    my ($value, $eps) = @_;

    $eps = 1E-6 unless defined $eps;

    if( abs($value) < $eps ) {
        return 0.0;
    }
    if( abs($value - 1) < $eps ) {
        return 1.0;
    }
    if( abs($value - 1/2) < $eps ) {
        return 1/2;
    }
    if( abs($value - 1/3) < $eps ) {
        return 1/3;
    }
    if( abs($value - 2/3) < $eps ) {
        return 2/3;
    }
    if( abs($value - 1/4) < $eps ) {
        return 1/4;
    }
    if( abs($value - 3/4) < $eps ) {
        return 3/4;
    }
    if( abs($value - 1/6) < $eps ) {
        return 1/6;
    }
    if( abs($value - 5/6) < $eps ) {
        return 5/6;
    }
    if( abs($value - 1.0) < $eps ) {
        return 1;
    }

    return $value;
}

sub snap_to_crystallographic
{
    my ($vector) = @_;

    for(@$vector) {
        if( ref $_ ) {
            snap_to_crystallographic( $_ );
        } else {
            $_ = snap_number_to_crystallographic( $_ );
        }
    }
    return $vector;
}

sub all_symops
{
    my ($self) = @_;

    return wantarray ? @{$self->{symops}} : $self->{symops};
}

sub all_symops_ref
{
    my ($self) = @_;
    my @symops = $self->all_symops();
    return \@symops;
}

sub insert_symop
    # N.B. This function has *quadratic* performance and thus is not
    # suitable for practical use on large spacegroups.
{
    my ($self, $symop) = @_;

    $symop = snap_to_crystallographic(symop_modulo_1( $symop ));

    if( $self->has_symop( $symop ) ) {
        return;
    }

    my @new_symops = ( $symop );
    push( @{$self->{symops}}, $symop );
    $self->{symop_hash}{string_from_symop($symop)} = $symop;
    $symop = undef;
    
    while( @new_symops ) {
        my $test_symop = shift( @new_symops );
        my @new_products = ();
        for my $group_symop (@{$self->{symops}}) {
            my $product = 
                snap_to_crystallographic(
                    symop_modulo_1(
                        symop_mul( $group_symop, $test_symop )
                    )
                );
            my $product_key = string_from_symop( $product );
            if( !exists $self->{symop_hash}{$product_key} ) {
                push( @new_products, $product );
                $self->{symop_hash}{$product_key} = $product;
            }
        }
        if( @new_products ) {
            push( @{$self->{symops}}, @new_products );
            push( @new_symops, @new_products );
        }
        if( $debug ) {
            print( STDERR ">>> Symops available: ",
                   int(@{$self->{symops}}), "\n" );
            for (@{$self->{symops}}) {
                print STDERR string_from_symop( $_ ), "\n";
            }
            print STDERR ">>> Symops to go: ", int(@new_symops), "\n";
            for (@new_symops) {
                print STDERR string_from_symop( $_ ), "\n";
            }
            print STDERR "\n";
        }
    }
}

sub insert_symops
{
    my ($self, $symops) = @_;

    for my $symop (@$symops) {
        $self->insert_symop( $symop );
    }
}

sub has_symop
{
    my ($self, $symop) = @_;

    for my $s (@{$self->{symops}}) {
        if( symops_are_equal( $s, $symop )) {
            return $s;
        }
    }
    return undef;
}

sub insert_symop_string
{
    my ($self, $symop_string) = @_;

    my $symop = symop_from_string( $symop_string );
    $self->insert_symop( $symop );
}

sub insert_symop_strings
{
    my ($self, $strings) = @_;

    for my $symop_string (@$strings) {
        $self->insert_symop_string( $symop_string );
    }
}

1;
