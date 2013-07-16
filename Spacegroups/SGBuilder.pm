#------------------------------------------------------------------------------
#$Author$
#$Date$ 
#$Revision$
#$URL$
#------------------------------------------------------------------------------
#*
#  A Perl object to build all spacegroup operators and spacegroup
#  description from symmetry operators supplied one by one or as a
#  list.
#**

package SGBuilder;
use strict;
use warnings;

use VectorAlgebra;
use SymopAlgebra qw( symop_mul symop_translation );
use SymopParse;

use fields qw( symops has_inversion inversion_translation centering_translations );

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

sub new { 
    my ($self) = @_;

    $self = fields::new($self) unless (ref $self);
    $self->{symops} = [ $unity_symop ];
    $self->{has_inversion} = 0;
    $self->{inversion_translation} = undef;
    $self->{centering_translations} = [];
    return $self;
}

sub print
{
    my ($self) = @_;

    print "nsymop:    ", int(@{$self->{symops}}), "\n";
    print "inversion: ", $self->{has_inversion}, "\n";
    print "centering: ";
    for (@{$self->{centering_translations}}) {
        local $, = ",";
        print @$_;
        print " ";
    }
    print "\n";
}

sub insert_translation
{
    my ($self, $translation) = @_;

    $translation = vector_modulo_1( $translation );

    if( vector_is_zero( $translation )) {
        return
    }
    for my $t (@{$self->{centering_translations}}) {
        if( vectors_are_equal( $t, $translation )) {
            return
        }
    }
    push( @{$self->{centering_translations}}, $translation );
}

sub insert_representative_matrix
{
    my ($self, $symop) = @_;

    my @candidates;

    push( @candidates, $symop );

    while( @candidates ) {
        my $candidate = shift( @candidates );
        push( @{$self->{symops}}, $candidate );
        for my $s (@{$self->{symops}}) {
            my $product = symop_mul( $s, $candidate );
            if( !$self->has_matrix( $product )) {
                push( @candidates, $product );
            }
        }
    }
}

sub insert_symop
{
    my ($self, $symop) = @_;

    if( SymopAlgebra::symop_is_inversion( $symop )) {
        if( $self->{has_inversion} ) {
            my $translation = SymopAlgebra::symop_translation( $symop );
            my $new_centering = vector_sub( $self->{inversion_translation},
                                            $translation );
            $self->insert_translation( $new_centering );
        } else {
            $self->{has_inversion} = 1;
            $self->{inversion_translation} = symop_translation( $symop );
        }
    }

    my $existing_symop;
    if( defined ($existing_symop = $self->has_matrix( $symop ))) {
        my $existing_translation = symop_translation( $existing_symop );
        my $translation = symop_translation( $symop );
        $self->insert_translation(
            scalar( vector_sub( $existing_translation, $translation )));
    } else {
        my $inverted_symop = symop_mul( $inversion_symop, $symop );
        if( defined
            ($existing_symop = $self->has_matrix( $inverted_symop ))) {
            my $existing_translation = symop_translation( $existing_symop );
            my $translation = symop_translation( $symop );
            $self->insert_translation(
                scalar( vector_sub( $existing_translation, $translation )));
        } else {
            $self->insert_representative_matrix( $symop );
        }
    }
}

sub has_matrix
{
    my ($self, $symop) = @_;

    for my $s (@{$self->{symops}}) {
        if( SymopAlgebra::symop_matrices_are_equal( $s, $symop )) {
            return $s;
        }
    }
    return undef;
}

sub insert_symop_string
{
    my ($self, $symop_string) = @_;

    my $symop = SymopParse::symop_from_string( $symop_string );
    $self->insert_symop( $symop );
}

1;
